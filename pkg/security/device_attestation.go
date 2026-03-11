package security

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"
)

// DeviceAttestor, Google Play Integrity ve Apple App Attest tokenlerini doğrular.

type DeviceAttestor struct {
	httpClient *http.Client
	androidAPIKey string
	appleTeamID   string
	appleKeyID    string
	appleKey      string
}

func NewDeviceAttestor() *DeviceAttestor {
	return &DeviceAttestor{
		httpClient: &http.Client{Timeout: 5 * time.Second},
		androidAPIKey: os.Getenv("PLAY_INTEGRITY_API_KEY"),
		appleTeamID:   os.Getenv("APPLE_TEAM_ID"),
		appleKeyID:    os.Getenv("APPLE_ATTEST_KEY_ID"),
		appleKey:      os.Getenv("APPLE_ATTEST_KEY"),
	}
}

// VerifyAndroidIntegrity, Google Play Integrity API'ye token göndererek cihaz bütünlüğünü doğrular.
// Gerçek entegrasyonda packageName ve nonce gibi alanlar da kullanılmalıdır.
func (d *DeviceAttestor) VerifyAndroidIntegrity(ctx context.Context, integrityToken string) (bool, error) {
	if d.androidAPIKey == "" {
		// Eğer config yoksa, prod ortamında bu hata olmalı; burada fail-closed tercih ediyoruz.
		return false, fmt.Errorf("play integrity api key not configured")
	}

	payload := map[string]string{
		"integrity_token": integrityToken,
	}
	b, _ := json.Marshal(payload)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost,
		"https://playintegrity.googleapis.com/v1/verifyIntegrity?key="+d.androidAPIKey,
		bytes.NewReader(b))
	if err != nil {
		return false, fmt.Errorf("create play integrity request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := d.httpClient.Do(req)
	if err != nil {
		return false, fmt.Errorf("play integrity http error: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return false, nil
	}

	// Burada response içeriğindeki deviceIntegrity vb. alanlara bakılmalıdır.
	// Örnek basitleştirme: status OK ise true döndürüyoruz.
	return true, nil
}

// VerifyAppleAttestation, App Attest token'ını Apple'ın doğrulama endpoint'i ile kontrol eder.
// Gerçek entegrasyonda JWT imzası, nonce ve appID kontrolleri yapılmalıdır.
func (d *DeviceAttestor) VerifyAppleAttestation(ctx context.Context, attestationToken string) (bool, error) {
	if d.appleKey == "" || d.appleTeamID == "" || d.appleKeyID == "" {
		return false, fmt.Errorf("apple attest config not configured")
	}

	// Burada normalde JWT imzası Apple'ın public key'leriyle doğrulanır.
	// Basitleştirilmiş placeholder: remote verification endpoint'i ile kontrol.

	payload := map[string]string{
		"attestation": attestationToken,
	}
	b, _ := json.Marshal(payload)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost,
		"https://appleid.apple.com/auth/attest", bytes.NewReader(b))
	if err != nil {
		return false, fmt.Errorf("create apple attest request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := d.httpClient.Do(req)
	if err != nil {
		return false, fmt.Errorf("apple attest http error: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return false, nil
	}

	return true, nil
}

