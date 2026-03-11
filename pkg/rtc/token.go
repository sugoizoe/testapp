package rtc

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"time"
)

// Bu paket, gerçek Agora/diğer sağlayıcı SDK'larına sarılabilecek
// basit, süre sınırlı bir RTC token üreticisi sağlar.

type Role string

const (
	RoleCaller Role = "caller"
	RoleCallee Role = "callee"
)

type Config struct {
	AppID        string
	AppSecret    []byte
	TokenTTLFree  time.Duration
	TokenTTLPrem  time.Duration
}

type TokenPayload struct {
	Channel   string    `json:"ch"`
	UserID    string    `json:"uid"`
	Role      Role      `json:"role"`
	ExpiresAt time.Time `json:"exp"`
}

type Service struct {
	cfg Config
}

func NewService(cfg Config) *Service {
	return &Service{cfg: cfg}
}

// GenerateToken: süre sınırlı, HMAC-SHA256 imzalı bir RTC token üretir.
// İstemci bu token'ı doğrudan WebRTC/3rd-party SDK'ya iletebilir ya da
// gateway servis tarafından doğrulatabilir.
func (s *Service) GenerateToken(channel, userID string, role Role, isPremium bool) (string, time.Time, error) {
	var ttl time.Duration
	if isPremium {
		ttl = s.cfg.TokenTTLPrem
	} else {
		ttl = s.cfg.TokenTTLFree
	}
	now := time.Now().UTC()
	exp := now.Add(ttl)

	payload := TokenPayload{
		Channel:   channel,
		UserID:    userID,
		Role:      role,
		ExpiresAt: exp,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("marshal rtc payload: %w", err)
	}

	mac := hmac.New(sha256.New, s.cfg.AppSecret)
	mac.Write(body)
	sig := mac.Sum(nil)

	tokenStruct := struct {
		AppID  string `json:"aid"`
		Body   string `json:"b64"`
		Sign   string `json:"sig"`
		Issued int64  `json:"iat"`
	}{
		AppID:  s.cfg.AppID,
		Body:   base64.RawURLEncoding.EncodeToString(body),
		Sign:   base64.RawURLEncoding.EncodeToString(sig),
		Issued: now.Unix(),
	}

	tokenBytes, err := json.Marshal(tokenStruct)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("marshal rtc token: %w", err)
	}

	token := base64.RawURLEncoding.EncodeToString(tokenBytes)
	return token, exp, nil
}

