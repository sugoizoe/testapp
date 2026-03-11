package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/example/datenow/internal/domain/chat"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ChatService struct {
	db *pgxpool.Pool
}

func NewChatService(db *pgxpool.Pool) *ChatService {
	return &ChatService{db: db}
}

// SendDateRequest: sadece eşleşmiş kullanıcılar ve en az bir taraf premium ise izin verilir.
func (s *ChatService) SendDateRequest(ctx context.Context, senderID string, req chat.SendDateRequest) error {
	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var (
		user1ID string
		user2ID string
	)

	// Match doğrulama ve tarafları bul
	if err := tx.QueryRow(ctx, `
		SELECT user1_id, user2_id
		FROM matches
		WHERE id = $1
	`, req.MatchID).Scan(&user1ID, &user2ID); err != nil {
		return fmt.Errorf("match not found: %w", err)
	}

	if senderID != user1ID && senderID != user2ID {
		return fmt.Errorf("sender is not part of match")
	}

	otherID := user1ID
	if senderID == user1ID {
		otherID = user2ID
	}

	var (
		senderPremium   bool
		otherPremium    bool
		senderExpiresAt *time.Time
		otherExpiresAt  *time.Time
	)

	if err := tx.QueryRow(ctx, `
		SELECT is_premium, premium_expires_at
		FROM users
		WHERE id = $1
	`, senderID).Scan(&senderPremium, &senderExpiresAt); err != nil {
		return fmt.Errorf("sender not found: %w", err)
	}

	if err := tx.QueryRow(ctx, `
		SELECT is_premium, premium_expires_at
		FROM users
		WHERE id = $1
	`, otherID).Scan(&otherPremium, &otherExpiresAt); err != nil {
		return fmt.Errorf("other user not found: %w", err)
	}

	now := time.Now().UTC()
	senderEffectivePremium := senderPremium && senderExpiresAt != nil && senderExpiresAt.After(now)
	otherEffectivePremium := otherPremium && otherExpiresAt != nil && otherExpiresAt.After(now)

	if !senderEffectivePremium && !otherEffectivePremium {
		return fmt.Errorf("at least one side must be premium for messaging")
	}

	contentJSON, err := json.Marshal(req.Content)
	if err != nil {
		return fmt.Errorf("marshal content: %w", err)
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO messages (match_id, sender_id, message_type, content)
		VALUES ($1, $2, 'DATE_REQUEST', $3)
	`, req.MatchID, senderID, contentJSON)
	if err != nil {
		return fmt.Errorf("insert message: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}

	return nil
}

