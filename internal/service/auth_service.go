package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/example/datenow/internal/domain/user"
	"github.com/example/datenow/pkg/security"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrInvalidRefresh     = errors.New("invalid refresh token")
)

type AuthService struct {
	db          *pgxpool.Pool
	passwordCfg security.Argon2Config
	jwtManager  *security.JWTManager
}

func NewAuthService(db *pgxpool.Pool, cfg security.Argon2Config, jwtManager *security.JWTManager) *AuthService {
	return &AuthService{
		db:          db,
		passwordCfg: cfg,
		jwtManager:  jwtManager,
	}
}

type AuthTokens struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

func (s *AuthService) Register(ctx context.Context, req user.RegisterRequest) (*AuthTokens, error) {
	now := time.Now()
	age := now.Year() - req.BirthDate.Year()
	if now.YearDay() < req.BirthDate.YearDay() {
		age--
	}
	if age < 18 {
		return nil, fmt.Errorf("must be at least 18 years old")
	}

	hashedPassword, err := security.HashPassword(req.Password, s.passwordCfg)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var userID string
	// 7 günlük trial: kayıt anında premium ve trial_used = TRUE
	trialExpires := now.AddDate(0, 0, 7)
	err = tx.QueryRow(ctx, `
		INSERT INTO users (email, password_hash, is_premium, premium_expires_at, trial_used, video_call_count, last_call_reset_date)
		VALUES (LOWER($1), $2, TRUE, $3, TRUE, 0, $4)
		RETURNING id
	`, req.Email, hashedPassword, trialExpires, now).Scan(&userID)
	if err != nil {
		return nil, fmt.Errorf("insert user: %w", err)
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO profiles (user_id, full_name, birth_date, gender)
		VALUES ($1, $2, $3, $4)
	`, userID, req.Email, req.BirthDate, req.Gender)
	if err != nil {
		return nil, fmt.Errorf("insert profile: %w", err)
	}

	accessToken, err := s.jwtManager.GenerateAccessToken(userID)
	if err != nil {
		return nil, fmt.Errorf("generate access token: %w", err)
	}
	refreshToken, err := s.jwtManager.GenerateRefreshToken(userID)
	if err != nil {
		return nil, fmt.Errorf("generate refresh token: %w", err)
	}

	rtHash := hashRefreshToken(refreshToken)
	claims, _ := s.jwtManager.ParseRefreshToken(refreshToken)

	_, err = tx.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, userID, rtHash, claims.ExpiresAt.Time)
	if err != nil {
		return nil, fmt.Errorf("insert refresh token: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return &AuthTokens{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (s *AuthService) Login(ctx context.Context, req user.LoginRequest) (*AuthTokens, error) {
	var (
		userID       string
		passwordHash string
	)

	err := s.db.QueryRow(ctx, `
		SELECT id, password_hash
		FROM users
		WHERE email = LOWER($1)
	`, req.Email).Scan(&userID, &passwordHash)
	if err != nil {
		return nil, ErrInvalidCredentials
	}

	ok, err := security.VerifyPassword(passwordHash, req.Password)
	if err != nil || !ok {
		return nil, ErrInvalidCredentials
	}

	accessToken, err := s.jwtManager.GenerateAccessToken(userID)
	if err != nil {
		return nil, fmt.Errorf("generate access token: %w", err)
	}
	refreshToken, err := s.jwtManager.GenerateRefreshToken(userID)
	if err != nil {
		return nil, fmt.Errorf("generate refresh token: %w", err)
	}

	rtHash := hashRefreshToken(refreshToken)
	claims, _ := s.jwtManager.ParseRefreshToken(refreshToken)

	_, err = s.db.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, userID, rtHash, claims.ExpiresAt.Time)
	if err != nil {
		return nil, fmt.Errorf("insert refresh token: %w", err)
	}

	return &AuthTokens{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (s *AuthService) Refresh(ctx context.Context, rawRefreshToken string) (*AuthTokens, error) {
	claims, err := s.jwtManager.ParseRefreshToken(rawRefreshToken)
	if err != nil {
		return nil, ErrInvalidRefresh
	}

	rtHash := hashRefreshToken(rawRefreshToken)

	var exists bool
	err = s.db.QueryRow(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM refresh_tokens
			WHERE user_id = $1
			  AND token_hash = $2
			  AND revoked_at IS NULL
			  AND expires_at > NOW()
		)
	`, claims.UserID, rtHash).Scan(&exists)
	if err != nil || !exists {
		return nil, ErrInvalidRefresh
	}

	accessToken, err := s.jwtManager.GenerateAccessToken(claims.UserID)
	if err != nil {
		return nil, fmt.Errorf("generate access token: %w", err)
	}

	newRefreshToken, err := s.jwtManager.GenerateRefreshToken(claims.UserID)
	if err != nil {
		return nil, fmt.Errorf("generate refresh token: %w", err)
	}
	newHash := hashRefreshToken(newRefreshToken)
	newClaims, _ := s.jwtManager.ParseRefreshToken(newRefreshToken)

	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		UPDATE refresh_tokens
		SET revoked_at = NOW()
		WHERE user_id = $1 AND token_hash = $2 AND revoked_at IS NULL
	`, claims.UserID, rtHash)
	if err != nil {
		return nil, fmt.Errorf("revoke old refresh token: %w", err)
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, claims.UserID, newHash, newClaims.ExpiresAt.Time)
	if err != nil {
		return nil, fmt.Errorf("insert new refresh token: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return &AuthTokens{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
	}, nil
}

func hashRefreshToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

