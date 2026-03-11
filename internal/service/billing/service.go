package billing

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Provider string

const (
	ProviderApple  Provider = "apple"
	ProviderGoogle Provider = "google"
)

type Config struct {
	AppleVerifyURL  string
	AppleSecret     string
	GoogleVerifyURL string
	GoogleAPIKey    string
	HTTPClient      *http.Client
}

type Service struct {
	db     *pgxpool.Pool
	cfg    Config
	client *http.Client
}

func NewService(db *pgxpool.Pool, cfg Config) *Service {
	client := cfg.HTTPClient
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &Service{
		db:     db,
		cfg:    cfg,
		client: client,
	}
}

type VerifyRequest struct {
	Provider    Provider
	Receipt     string
	Currency    string
	AmountCents int
}

type VerifyResult struct {
	ExpiresAt   time.Time
	PurchasedAt time.Time
	Status      string
}

// VerifyAndActivateSubscription:
// 1) Makbuzu Apple/Google ile doğrular
// 2) subscriptions tablosuna log yazar
// 3) users tablosunda premium_expires_at alanını günceller (varsa ekler).
func (s *Service) VerifyAndActivateSubscription(ctx context.Context, userID string, req VerifyRequest) (*VerifyResult, error) {
	var (
		res VerifyResult
		err error
	)

	switch req.Provider {
	case ProviderApple:
		res, err = s.verifyApple(ctx, req.Receipt)
	case ProviderGoogle:
		res, err = s.verifyGoogle(ctx, req.Receipt)
	default:
		return nil, fmt.Errorf("unsupported provider")
	}
	if err != nil {
		return nil, err
	}

	raw := map[string]any{
		"provider": req.Provider,
		"receipt":  req.Receipt,
	}
	rawJSON, _ := json.Marshal(raw)

	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var receiptID string
	receiptID = "" // Provider'a göre doldurulabilir; burada basitleştirildi.

	_, err = tx.Exec(ctx, `
		INSERT INTO subscriptions (
			user_id, provider, receipt_id, raw_receipt,
			currency, amount_cents, status, purchased_at, expires_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`, userID, string(req.Provider), receiptID, rawJSON,
		req.Currency, req.AmountCents, res.Status, res.PurchasedAt, res.ExpiresAt)
	if err != nil {
		return nil, fmt.Errorf("insert subscription: %w", err)
	}

	// Premium süresini uzat: eğer mevcut premium_expires_at gelecekteyse üzerine ekle,
	// değilse bugünden itibaren başlat.
	_, err = tx.Exec(ctx, `
		UPDATE users
		SET
			is_premium = TRUE,
			premium_expires_at = CASE
				WHEN premium_expires_at IS NOT NULL AND premium_expires_at > NOW()
					THEN premium_expires_at + ($1::interval)
				ELSE $2
			END
		WHERE id = $3
	`, res.ExpiresAt.Sub(res.PurchasedAt), res.ExpiresAt, userID)
	if err != nil {
		return nil, fmt.Errorf("update user premium: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return &res, nil
}

// --- Apple ---

func (s *Service) verifyApple(ctx context.Context, receipt string) (VerifyResult, error) {
	body := map[string]string{
		"receipt-data": receipt,
		"password":     s.cfg.AppleSecret,
	}
	b, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.cfg.AppleVerifyURL, bytes.NewReader(b))
	if err != nil {
		return VerifyResult{}, fmt.Errorf("apple request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.client.Do(req)
	if err != nil {
		return VerifyResult{}, fmt.Errorf("apple verify: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return VerifyResult{}, fmt.Errorf("apple verify status: %d", resp.StatusCode)
	}

	// Burada gerçek Apple response'u parse etmek gerekir; basit taklit:
	now := time.Now().UTC()
	return VerifyResult{
		PurchasedAt: now,
		ExpiresAt:   now.AddDate(0, 1, 0), // 1 aylık abonelik varsayımı
		Status:      "active",
	}, nil
}

// --- Google ---

func (s *Service) verifyGoogle(ctx context.Context, receipt string) (VerifyResult, error) {
	body := map[string]string{
		"token": receipt,
		"key":   s.cfg.GoogleAPIKey,
	}
	b, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.cfg.GoogleVerifyURL, bytes.NewReader(b))
	if err != nil {
		return VerifyResult{}, fmt.Errorf("google request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.client.Do(req)
	if err != nil {
		return VerifyResult{}, fmt.Errorf("google verify: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return VerifyResult{}, fmt.Errorf("google verify status: %d", resp.StatusCode)
	}

	now := time.Now().UTC()
	return VerifyResult{
		PurchasedAt: now,
		ExpiresAt:   now.AddDate(0, 1, 0),
		Status:      "active",
	}, nil
}

