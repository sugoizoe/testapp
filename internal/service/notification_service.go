package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type NotificationService struct {
	db        *pgxpool.Pool
	serverKey string
	client    *http.Client
}

func NewNotificationService(db *pgxpool.Pool, serverKey string) *NotificationService {
	return &NotificationService{
		db:        db,
		serverKey: serverKey,
		client: &http.Client{
			Timeout: 5 * time.Second,
		},
	}
}

func (s *NotificationService) RegisterFCMToken(ctx context.Context, userID, token, deviceType string) error {
	if token == "" || userID == "" {
		return fmt.Errorf("invalid token or userID")
	}

	_, err := s.db.Exec(ctx, `
		INSERT INTO fcm_tokens (user_id, token, device_type, updated_at)
		VALUES ($1, $2, $3, NOW())
		ON CONFLICT (token) DO UPDATE
			SET user_id = EXCLUDED.user_id,
			    device_type = EXCLUDED.device_type,
			    updated_at = NOW()
	`, userID, token, deviceType)
	if err != nil {
		return fmt.Errorf("upsert fcm_token: %w", err)
	}
	return nil
}

func (s *NotificationService) SendPushNotification(ctx context.Context, userID, title, body string, data map[string]string) error {
	if s.serverKey == "" {
		return nil
	}

	rows, err := s.db.Query(ctx, `
		SELECT token FROM fcm_tokens
		WHERE user_id = $1
	`, userID)
	if err != nil {
		return fmt.Errorf("select fcm_tokens: %w", err)
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var t string
		if err := rows.Scan(&t); err != nil {
			return fmt.Errorf("scan token: %w", err)
		}
		tokens = append(tokens, t)
	}

	if len(tokens) == 0 {
		return nil
	}

	payload := map[string]any{
		"registration_ids": tokens,
		"notification": map[string]string{
			"title": title,
			"body":  body,
		},
		"data": data,
	}
	b, _ := json.Marshal(payload)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://fcm.googleapis.com/fcm/send", bytes.NewReader(b))
	if err != nil {
		return fmt.Errorf("create fcm request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "key="+s.serverKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("send fcm request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("fcm error status: %d", resp.StatusCode)
	}

	return nil
}

