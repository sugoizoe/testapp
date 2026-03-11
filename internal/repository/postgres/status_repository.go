package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/example/datenow/internal/domain/status"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type StatusRepository struct {
	db *pgxpool.Pool
}

func NewStatusRepository(db *pgxpool.Pool) *StatusRepository {
	return &StatusRepository{db: db}
}

func (r *StatusRepository) CreateStatus(ctx context.Context, userID, content string, lat, lon float64, ttlHours int) (string, error) {
	if ttlHours <= 0 || ttlHours > 24 {
		ttlHours = 24
	}
	now := time.Now().UTC()
	expiresAt := now.Add(time.Duration(ttlHours) * time.Hour)

	var id string
	err := r.db.QueryRow(ctx, `
		INSERT INTO statuses (user_id, content, location, expires_at)
		VALUES ($1, $2,
		        ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography,
		        $5)
		RETURNING id
	`, userID, content, lon, lat, expiresAt).Scan(&id)
	if err != nil {
		return "", fmt.Errorf("insert status: %w", err)
	}
	return id, nil
}

func (r *StatusRepository) GetNearbyActiveStatuses(ctx context.Context, viewerID string, lat, lon, radiusKm float64, limit int) ([]status.Status, error) {
	if radiusKm <= 0 {
		radiusKm = 10
	}
	if radiusKm > 1000 {
		radiusKm = 1000
	}
	if limit <= 0 {
		limit = 50
	}

	rows, err := r.db.Query(ctx, `
		SELECT
			s.id,
			s.user_id,
			s.content,
			ST_Y(ST_AsText(s.location::geometry)) AS lat,
			ST_X(ST_AsText(s.location::geometry)) AS lon,
			s.expires_at,
			s.is_active,
			s.created_at,
			ST_Distance(
				s.location,
				ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
			) / 1000.0 AS distance_km
		FROM statuses s
		LEFT JOIN user_blocks ub1
			ON ub1.blocker_id = s.user_id
			AND ub1.blocked_id = $5
		LEFT JOIN user_blocks ub2
			ON ub2.blocker_id = $5
			AND ub2.blocked_id = s.user_id
		WHERE
			s.is_active = TRUE
			AND s.expires_at > NOW()
			AND ub1.blocker_id IS NULL
			AND ub2.blocker_id IS NULL
			AND ST_DWithin(
				s.location,
				ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
				$3 * 1000.0
			)
		ORDER BY distance_km ASC, s.created_at DESC
		LIMIT $4
	`, lon, lat, radiusKm, limit, viewerID)
	if err != nil {
		return nil, fmt.Errorf("query nearby statuses: %w", err)
	}
	defer rows.Close()

	var results []status.Status
	for rows.Next() {
		var s status.Status
		var distance float64
		if err := rows.Scan(
			&s.ID,
			&s.UserID,
			&s.Content,
			&s.Lat,
			&s.Lon,
			&s.ExpiresAt,
			&s.IsActive,
			&s.CreatedAt,
			&distance,
		); err != nil {
			return nil, fmt.Errorf("scan status: %w", err)
		}
		s.DistanceKm = &distance
		results = append(results, s)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows error: %w", err)
	}

	return results, nil
}

func (r *StatusRepository) CreateStatusRequest(ctx context.Context, statusID, requesterID string) (string, error) {
	var id string
	err := r.db.QueryRow(ctx, `
		INSERT INTO status_requests (status_id, requester_id, state)
		VALUES ($1, $2, 'pending')
		ON CONFLICT (status_id, requester_id) DO UPDATE
			SET state = 'pending',
			    created_at = NOW()
		RETURNING id
	`, statusID, requesterID).Scan(&id)
	if err != nil {
		return "", fmt.Errorf("insert status_request: %w", err)
	}
	return id, nil
}

func (r *StatusRepository) AcceptRequestAndCloseStatus(ctx context.Context, requestID, ownerID string) (*status.AcceptanceResult, error) {
	tx, err := r.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var (
		statusID   string
		requesterID string
	)

	// Kilitle ve doğrula: istek + ait olduğu status
	err = tx.QueryRow(ctx, `
		SELECT sr.status_id, sr.requester_id
		FROM status_requests sr
		JOIN statuses s ON s.id = sr.status_id
		WHERE sr.id = $1
		  AND sr.state = 'pending'
		  AND s.user_id = $2
		  AND s.is_active = TRUE
		  AND s.expires_at > NOW()
		FOR UPDATE OF sr
	`, requestID, ownerID).Scan(&statusID, &requesterID)
	if err != nil {
		return nil, fmt.Errorf("load request/status: %w", err)
	}

	// Status kaydını da kilitle
	var dummy string
	if err := tx.QueryRow(ctx, `
		SELECT id FROM statuses
		WHERE id = $1
		FOR UPDATE
	`, statusID).Scan(&dummy); err != nil {
		return nil, fmt.Errorf("lock status: %w", err)
	}

	// Seçilen isteği accepted yap
	if _, err := tx.Exec(ctx, `
		UPDATE status_requests
		SET state = 'accepted'
		WHERE id = $1
	`, requestID); err != nil {
		return nil, fmt.Errorf("accept request: %w", err)
	}

	// Diğer bekleyenleri rejected yap
	if _, err := tx.Exec(ctx, `
		UPDATE status_requests
		SET state = 'rejected'
		WHERE status_id = $1
		  AND id <> $2
		  AND state = 'pending'
	`, statusID, requestID); err != nil {
		return nil, fmt.Errorf("reject others: %w", err)
	}

	// Durumu kapat
	if _, err := tx.Exec(ctx, `
		UPDATE statuses
		SET is_active = FALSE
		WHERE id = $1
	`, statusID); err != nil {
		return nil, fmt.Errorf("close status: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return &status.AcceptanceResult{
		StatusID:   statusID,
		OwnerID:    ownerID,
		RequesterID: requesterID,
	}, nil
}

