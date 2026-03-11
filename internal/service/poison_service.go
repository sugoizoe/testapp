package service

import (
	"crypto/rand"
	"encoding/hex"
	"math"
	mathrand "math/rand"
	"time"
)

// PoisonedProfile, keşfet endpoint'i için sahte profil modelidir.
type PoisonedProfile struct {
	UserID     string  `json:"user_id"`
	FullName   string  `json:"full_name"`
	Age        int     `json:"age"`
	Gender     string  `json:"gender"`
	City       string  `json:"city"`
	Country    string  `json:"country"`
	DistanceKm float64 `json:"distance_km"`
}

type PoisonService struct{}

func NewPoisonService() *PoisonService {
	// math/rand için kriptografik seed
	var b [8]byte
	if _, err := rand.Read(b[:]); err == nil {
		mathrand.Seed(int64(binaryToUint64(b[:]))) // best-effort
	}
	return &PoisonService{}
}

func (s *PoisonService) GenerateFakeDiscoveryPayload(count int) []PoisonedProfile {
	if count <= 0 {
		count = 10
	}
	firstNames := []string{"Deniz", "Efe", "Arda", "Mert", "Alp", "Can", "Bora", "Demir"}
	lastNames := []string{"Yılmaz", "Demir", "Kaya", "Çelik", "Öztürk", "Aydın", "Yalçın"}
	cities := []string{"Atlantis", "Night City", "Neo Tokyo", "Valhalla", "Rapture"}
	countries := []string{"Neverland", "Utopia", "Wakanda"}
	genders := []string{"male", "female", "other"}

	out := make([]PoisonedProfile, 0, count)
	for i := 0; i < count; i++ {
		fn := firstNames[mathrand.Intn(len(firstNames))]
		ln := lastNames[mathrand.Intn(len(lastNames))]
		city := cities[mathrand.Intn(len(cities))]
		country := countries[mathrand.Intn(len(countries))]
		gender := genders[mathrand.Intn(len(genders))]
		age := 18 + mathrand.Intn(22) // 18-39

		out = append(out, PoisonedProfile{
			UserID:     randomID(),
			FullName:   fn + " " + ln,
			Age:        age,
			Gender:     gender,
			City:       city,
			Country:    country,
			DistanceKm: math.Round((0.5+mathrand.Float64()*49.5)*10) / 10, // 0.5 - 50 km
		})
	}

	return out
}

func randomID() string {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		// fallback
		return hex.EncodeToString([]byte(time.Now().Format(time.RFC3339Nano)))
	}
	return hex.EncodeToString(b[:])
}

func binaryToUint64(b []byte) uint64 {
	var v uint64
	for _, x := range b {
		v = (v << 8) | uint64(x)
	}
	return v
}

