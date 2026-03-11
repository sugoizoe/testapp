package security

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var (
	ErrInvalidToken     = errors.New("invalid token")
	ErrExpiredToken     = errors.New("expired token")
	ErrUnexpectedClaims = errors.New("unexpected claims type")
)

type JWTConfig struct {
	AccessSecret    []byte
	RefreshSecret   []byte
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration
	Issuer          string
}

type CustomClaims struct {
	UserID string `json:"uid"`
	jwt.RegisteredClaims
}

type JWTManager struct {
	cfg JWTConfig
}

func NewJWTManager(cfg JWTConfig) *JWTManager {
	return &JWTManager{cfg: cfg}
}

func (m *JWTManager) GenerateAccessToken(userID string) (string, error) {
	now := time.Now().UTC()
	claims := CustomClaims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    m.cfg.Issuer,
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(m.cfg.AccessTokenTTL)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(m.cfg.AccessSecret)
}

func (m *JWTManager) GenerateRefreshToken(userID string) (string, error) {
	now := time.Now().UTC()
	claims := CustomClaims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    m.cfg.Issuer,
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(m.cfg.RefreshTokenTTL)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(m.cfg.RefreshSecret)
}

func (m *JWTManager) ParseAccessToken(tokenStr string) (*CustomClaims, error) {
	return m.parse(tokenStr, m.cfg.AccessSecret)
}

func (m *JWTManager) ParseRefreshToken(tokenStr string) (*CustomClaims, error) {
	return m.parse(tokenStr, m.cfg.RefreshSecret)
}

func (m *JWTManager) parse(tokenStr string, secret []byte) (*CustomClaims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &CustomClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, ErrInvalidToken
		}
		return secret, nil
	})
	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrExpiredToken
		}
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*CustomClaims)
	if !ok || !token.Valid {
		return nil, ErrUnexpectedClaims
	}

	return claims, nil
}

