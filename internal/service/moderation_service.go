package service

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ModerationService struct {
	db *pgxpool.Pool
}

func NewModerationService(db *pgxpool.Pool) *ModerationService {
	return &ModerationService{db: db}
}

func (s *ModerationService) BlockUser(ctx context.Context, blockerID, blockedID string) error {
	if blockerID == blockedID {
		return nil
	}

	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	// Engelleme kaydını oluştur (idempotent)
	if _, err := tx.Exec(ctx, `
		INSERT INTO user_blocks (blocker_id, blocked_id)
		VALUES ($1, $2)
		ON CONFLICT (blocker_id, blocked_id) DO NOTHING
	`, blockerID, blockedID); err != nil {
		return fmt.Errorf("insert user_block: %w", err)
	}

	// Aralarındaki mevcut eşleşmeleri temizle
	if _, err := tx.Exec(ctx, `
		DELETE FROM matches
		WHERE (user1_id = $1 AND user2_id = $2)
		   OR (user1_id = $2 AND user2_id = $1)
	`, blockerID, blockedID); err != nil {
		return fmt.Errorf("delete matches: %w", err)
	}

	// İki kullanıcı arasındaki status isteklerini reddet ve ilgili durumları pasif et
	if _, err := tx.Exec(ctx, `
		UPDATE status_requests sr
		SET state = 'rejected'
		FROM statuses s
		WHERE sr.status_id = s.id
		  AND sr.state = 'pending'
		  AND (
		    (s.user_id = $1 AND sr.requester_id = $2) OR
		    (s.user_id = $2 AND sr.requester_id = $1)
		  )
	`, blockerID, blockedID); err != nil {
		return fmt.Errorf("reject status_requests: %w", err)
	}

	if _, err := tx.Exec(ctx, `
		UPDATE statuses s
		SET is_active = FALSE
		WHERE s.is_active = TRUE
		  AND EXISTS (
		    SELECT 1
		    FROM status_requests sr
		    WHERE sr.status_id = s.id
		      AND sr.state = 'rejected'
		      AND (
		        (s.user_id = $1 AND sr.requester_id = $2) OR
		        (s.user_id = $2 AND sr.requester_id = $1)
		      )
		  )
	`, blockerID, blockedID); err != nil {
		return fmt.Errorf("deactivate statuses: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}

	return nil
}

type ReportRequest struct {
	ReporterID string
	ReportedID string
	Reason     string
	Description string
	ContextID  *string
}

func (s *ModerationService) ReportUser(ctx context.Context, req ReportRequest) error {
	if req.ReporterID == "" || req.ReportedID == "" || req.Reason == "" {
		return fmt.Errorf("invalid report request")
	}

	_, err := s.db.Exec(ctx, `
		INSERT INTO user_reports (reporter_id, reported_id, reason, description, context_id)
		VALUES ($1, $2, $3, NULLIF($4, ''), $5)
	`, req.ReporterID, req.ReportedID, req.Reason, req.Description, req.ContextID)
	if err != nil {
		return fmt.Errorf("insert user_report: %w", err)
	}
	return nil
}

