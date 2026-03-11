package security

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"os"
)

// CryptoService AES-256-GCM ile uygulama seviyesinde şifreleme sağlar.

type CryptoService struct {
	aead cipher.AEAD
}

// NewCryptoService, verilen key'den (rastgele uzunlukta olabilir) AES-256-GCM AEAD üretir.
func NewCryptoService(rawKey []byte) (*CryptoService, error) {
	if len(rawKey) == 0 {
		return nil, errors.New("crypto key is empty")
	}
	// Key'i her zaman 32 byte'a (AES-256) indirgemek için SHA-256 kullanıyoruz.
	key := sha256.Sum256(rawKey)

	block, err := aes.NewCipher(key[:])
	if err != nil {
		return nil, fmt.Errorf("new cipher: %w", err)
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, fmt.Errorf("new gcm: %w", err)
	}
	return &CryptoService{aead: aead}, nil
}

// NewCryptoServiceFromEnv, CRYPTO_MASTER_KEY env değişkeninden key üretir.
func NewCryptoServiceFromEnv() (*CryptoService, error) {
	raw := os.Getenv("CRYPTO_MASTER_KEY")
	if raw == "" {
		return nil, errors.New("CRYPTO_MASTER_KEY not set")
	}
	return NewCryptoService([]byte(raw))
}

// Encrypt, verilen plaintext'i AES-256-GCM ile şifreler ve nonce+ciphertext'i döner.
func (c *CryptoService) Encrypt(plaintext []byte) ([]byte, error) {
	nonce := make([]byte, c.aead.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, fmt.Errorf("generate nonce: %w", err)
	}
	ciphertext := c.aead.Seal(nil, nonce, plaintext, nil)
	return append(nonce, ciphertext...), nil
}

// Decrypt, Encrypt ile üretilen nonce+ciphertext formatındaki veriyi çözer.
func (c *CryptoService) Decrypt(data []byte) ([]byte, error) {
	nonceSize := c.aead.NonceSize()
	if len(data) < nonceSize {
		return nil, errors.New("ciphertext too short")
	}
	nonce, ciphertext := data[:nonceSize], data[nonceSize:]
	plaintext, err := c.aead.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return nil, fmt.Errorf("decrypt: %w", err)
	}
	return plaintext, nil
}

// EncryptString, string'i şifreleyip base64 URL-safe string olarak döner.
func (c *CryptoService) EncryptString(s string) (string, error) {
	enc, err := c.Encrypt([]byte(s))
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(enc), nil
}

// DecryptString, EncryptString ile üretilen base64 string'i çözer.
func (c *CryptoService) DecryptString(s string) (string, error) {
	data, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return "", fmt.Errorf("decode base64: %w", err)
	}
	dec, err := c.Decrypt(data)
	if err != nil {
		return "", err
	}
	return string(dec), nil
}

