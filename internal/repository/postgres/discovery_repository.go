package postgres

import (
	"context"
	"fmt"

	"github.com/example/datenow/internal/domain/match"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type DiscoveryRepository struct {
	db *pgxpool.Pool
}

func NewDiscoveryRepository(db *pgxpool.Pool) *DiscoveryRepository {
	return &DiscoveryRepository{db: db}
}

func (r *DiscoveryRepository) GetNearbyProfiles(ctx context.Context, userID string, radiusKm float64, limit int) ([]match.NearbyProfileResponse, error) {
	if limit <= 0 {
		limit = 50
	}

	var (
		rows pgx.Rows
		err  error
	)

	// radiusKm < 0 ise mesafe filtresi olmadan tüm profilleri getir (ülke / dünya çapı)
	if radiusKm < 0 {
		rows, err = r.db.Query(ctx, `
		SELECT
			p_other.user_id,
			p_other.full_name,
			EXTRACT(YEAR FROM age(CURRENT_DATE, p_other.birth_date))::int AS age,
			p_other.gender,
			COALESCE(p_other.bio, ''),
			COALESCE(p_other.city, ''),
			COALESCE(p_other.country, ''),
			ST_Distance(p_self.location, p_other.location) / 1000.0 AS distance_km,
			p_other.attributes
		FROM profiles AS p_self
		JOIN profiles AS p_other
			ON p_other.user_id <> p_self.user_id
		JOIN users u_other
			ON u_other.id = p_other.user_id
		LEFT JOIN user_blocks ub1
			ON ub1.blocker_id = p_self.user_id
			AND ub1.blocked_id = p_other.user_id
		LEFT JOIN user_blocks ub2
			ON ub2.blocker_id = p_other.user_id
			AND ub2.blocked_id = p_self.user_id
		WHERE
			p_self.user_id = $1
			AND p_self.location IS NOT NULL
			AND p_other.location IS NOT NULL
			AND ub1.blocker_id IS NULL
			AND ub2.blocker_id IS NULL
			AND u_other.is_shadowbanned = FALSE
			AND (
				p_self.target_gender_preference = 'any'
				OR (p_self.target_gender_preference = 'both' AND p_other.gender IN ('male', 'female'))
				OR (p_self.target_gender_preference IN ('male', 'female') AND p_other.gender = p_self.target_gender_preference)
			)
			AND NOT EXISTS (
				SELECT 1
				FROM swipes s
				WHERE s.swiper_id = $1
				  AND s.target_id = p_other.user_id
			)
		ORDER BY distance_km ASC
		LIMIT $2
	`, userID, limit)
	} else {
		rows, err = r.db.Query(ctx, `
		SELECT
			p_other.user_id,
			p_other.full_name,
			EXTRACT(YEAR FROM age(CURRENT_DATE, p_other.birth_date))::int AS age,
			p_other.gender,
			COALESCE(p_other.bio, ''),
			COALESCE(p_other.city, ''),
			COALESCE(p_other.country, ''),
			ST_Distance(p_self.location, p_other.location) / 1000.0 AS distance_km,
			p_other.attributes
		FROM profiles AS p_self
		JOIN profiles AS p_other
			ON p_other.user_id <> p_self.user_id
		JOIN users u_other
			ON u_other.id = p_other.user_id
		LEFT JOIN user_blocks ub1
			ON ub1.blocker_id = p_self.user_id
			AND ub1.blocked_id = p_other.user_id
		LEFT JOIN user_blocks ub2
			ON ub2.blocker_id = p_other.user_id
			AND ub2.blocked_id = p_self.user_id
		WHERE
			p_self.user_id = $1
			AND p_self.location IS NOT NULL
			AND p_other.location IS NOT NULL
			AND ub1.blocker_id IS NULL
			AND ub2.blocker_id IS NULL
			AND u_other.is_shadowbanned = FALSE
			AND ST_DWithin(
				p_self.location,
				p_other.location,
				$2 * 1000.0
			)
			AND (
				p_self.target_gender_preference = 'any'
				OR (p_self.target_gender_preference = 'both' AND p_other.gender IN ('male', 'female'))
				OR (p_self.target_gender_preference IN ('male', 'female') AND p_other.gender = p_self.target_gender_preference)
			)
			AND NOT EXISTS (
				SELECT 1
				FROM swipes s
				WHERE s.swiper_id = $1
				  AND s.target_id = p_other.user_id
			)
		ORDER BY distance_km ASC
		LIMIT $3
	`, userID, radiusKm, limit)
	}
	if err != nil {
		return nil, fmt.Errorf("query nearby profiles: %w", err)
	}
	defer rows.Close()

	var results []match.NearbyProfileResponse
	for rows.Next() {
		var resp match.NearbyProfileResponse
		if err := rows.Scan(
			&resp.UserID,
			&resp.FullName,
			&resp.Age,
			&resp.Gender,
			&resp.Bio,
			&resp.City,
			&resp.Country,
			&resp.DistanceKm,
			&resp.Attributes,
		); err != nil {
			return nil, fmt.Errorf("scan nearby profile: %w", err)
		}
		results = append(results, resp)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows error: %w", err)
	}

	return results, nil
}

type SwipeResult struct {
	IsMatch bool
	MatchID *string
}

func (r *DiscoveryRepository) RecordSwipeAndCheckMatch(ctx context.Context, swiperID, targetID, action string) (*SwipeResult, error) {
	if swiperID == targetID {
		return &SwipeResult{IsMatch: false, MatchID: nil}, nil
	}

	tx, err := r.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		INSERT INTO swipes (swiper_id, target_id, action)
		VALUES ($1, $2, $3)
		ON CONFLICT (swiper_id, target_id) DO UPDATE
			SET action = EXCLUDED.action,
			    created_at = NOW()
	`, swiperID, targetID, action)
	if err != nil {
		return nil, fmt.Errorf("insert swipe: %w", err)
	}

	if action != "like" {
		if err := tx.Commit(ctx); err != nil {
			return nil, fmt.Errorf("commit tx: %w", err)
		}
		return &SwipeResult{IsMatch: false, MatchID: nil}, nil
	}

	var reciprocalLike bool
	if err := tx.QueryRow(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM swipes
			WHERE swiper_id = $2
			  AND target_id = $1
			  AND action = 'like'
		)
	`, swiperID, targetID).Scan(&reciprocalLike); err != nil {
		return nil, fmt.Errorf("check reciprocal like: %w", err)
	}

	if !reciprocalLike {
		if err := tx.Commit(ctx); err != nil {
			return nil, fmt.Errorf("commit tx: %w", err)
		}
		return &SwipeResult{IsMatch: false, MatchID: nil}, nil
	}

	var matchID *string
	if err := tx.QueryRow(ctx, `
		INSERT INTO matches (user1_id, user2_id)
		VALUES (LEAST($1, $2), GREATEST($1, $2))
		ON CONFLICT (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id)) DO NOTHING
		RETURNING id
	`, swiperID, targetID).Scan(&matchID); err != nil {
		if err != pgx.ErrNoRows {
			return nil, fmt.Errorf("insert match: %w", err)
		}

		var existingID string
		if err := tx.QueryRow(ctx, `
			SELECT id FROM matches
			WHERE user1_id = LEAST($1, $2)
			  AND user2_id = GREATEST($1, $2)
		`, swiperID, targetID).Scan(&existingID); err != nil {
			return nil, fmt.Errorf("get existing match: %w", err)
		}
		matchID = &existingID
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return &SwipeResult{IsMatch: true, MatchID: matchID}, nil
}

