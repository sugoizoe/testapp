package service

import (
	"context"
	"math"

	"github.com/example/datenow/internal/domain/match"
	"github.com/example/datenow/internal/repository/postgres"
)

type DiscoveryService struct {
	repo *postgres.DiscoveryRepository
}

func NewDiscoveryService(repo *postgres.DiscoveryRepository) *DiscoveryService {
	return &DiscoveryService{repo: repo}
}

func (s *DiscoveryService) GetNearbyProfiles(ctx context.Context, userID string, radiusKm float64, limit int) ([]match.NearbyProfileResponse, error) {
	// radiusKm == 0  -> varsayılan 10 km
	// radiusKm  > 0  -> max 1000 km (ülke çapı)
	// radiusKm  < 0  -> sınırsız (tüm Türkiye / dünya)
	if !isFinite(radiusKm) {
		radiusKm = 10
	}
	if radiusKm == 0 {
		radiusKm = 10
	}
	if radiusKm > 0 && radiusKm > 1000 {
		radiusKm = 1000
	}
	// radiusKm < 0 ise repository tarafında mesafe filtresi tamamen kaldırılacak.
	return s.repo.GetNearbyProfiles(ctx, userID, radiusKm, limit)
}

func (s *DiscoveryService) Swipe(ctx context.Context, swiperID string, req match.SwipeRequest) (*postgres.SwipeResult, error) {
	return s.repo.RecordSwipeAndCheckMatch(ctx, swiperID, req.TargetID, req.Action)
}

func isFinite(f float64) bool {
	return !math.IsNaN(f) && !math.IsInf(f, 0)
}

