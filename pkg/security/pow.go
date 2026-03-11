package security

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"math/bits"
)

// Proof-of-Work challenge: hash(seed || nonce) en az Difficulty kadar
// leading zero bit içermelidir.

type PoWChallenge struct {
	Seed       string `json:"seed"`
	Difficulty uint8  `json:"difficulty"`
}

// GeneratePoWChallenge, verilen zorluk seviyesinde yeni bir PoW challenge üretir.
func GeneratePoWChallenge(difficulty uint8) (*PoWChallenge, error) {
	if difficulty == 0 {
		difficulty = 16
	}
	seedBytes := make([]byte, 16)
	if _, err := rand.Read(seedBytes); err != nil {
		return nil, fmt.Errorf("generate seed: %w", err)
	}
	return &PoWChallenge{
		Seed:       base64.RawURLEncoding.EncodeToString(seedBytes),
		Difficulty: difficulty,
	}, nil
}

// VerifyPoWNonce, istemciden gelen nonce'ın challenge'ı sağladığını doğrular.
func VerifyPoWNonce(ch PoWChallenge, nonce string) bool {
	seedBytes, err := base64.RawURLEncoding.DecodeString(ch.Seed)
	if err != nil {
		return false
	}
	h := sha256.New()
	h.Write(seedBytes)
	h.Write([]byte(nonce))
	sum := h.Sum(nil)

	// leading zero bits say
	var zeros uint8
	for _, b := range sum {
		lz := uint8(bits.LeadingZeros8(b))
		zeros += lz
		if lz != 8 {
			break
		}
	}
	return zeros >= ch.Difficulty
}

