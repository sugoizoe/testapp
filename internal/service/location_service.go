package service

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type LocationService struct {
	db *pgxpool.Pool
}

func NewLocationService(db *pgxpool.Pool) *LocationService {
	return &LocationService{db: db}
}

// UpdateLocation: kullanıcının konumunu günceller, önceki konuma göre hız hesabı yapar.
// Eğer hız > 1000 km/s ise güncellemeyi reddeder ve kullanıcıyı shadowban eder.
func (s *LocationService) UpdateLocation(ctx context.Context, userID string, lat, lon float64) error {
	// Önce önceki konum ve timestamp'i al
	var (
		prevLat  *float64
		prevLon  *float64
		prevTime *time.Time
	)

	err := s.db.QueryRow(ctx, `
		SELECT lat, lon, location_updated_at
		FROM profiles
		WHERE user_id = $1
	`, userID).Scan(&prevLat, &prevLon, &prevTime)
	if err != nil {
		return fmt.Errorf("select previous location: %w", err)
	}

	now := time.Now().UTC()

	// Eğer önceki konum yoksa doğrudan güncelle
	if prevLat == nil || prevLon == nil || prevTime == nil {
		_, err := s.db.Exec(ctx, `
			UPDATE profiles
			SET lat = $2, lon = $3,
			    location_updated_at = $4
			WHERE user_id = $1
		`, userID, lat, lon, now)
		if err != nil {
			return fmt.Errorf("update initial location: %w", err)
		}
		return nil
	}

	// Mesafe ve zaman farkını PostGIS ile hesapla
	var (
		distKm float64
		hours  float64
	)
	err = s.db.QueryRow(ctx, `
		WITH prev AS (
			SELECT lat, lon, location_updated_at
			FROM profiles
			WHERE user_id = $1
		)
		SELECT
			haversine_distance_km(prev.lat, prev.lon, $2, $3) AS dist_km,
			EXTRACT(EPOCH FROM ($4 - prev.location_updated_at)) / 3600.0 AS hours
		FROM prev
	`, userID, lat, lon, now).Scan(&distKm, &hours)
	if err != nil {
		return fmt.Errorf("compute distance/time: %w", err)
	}

	if hours <= 0 {
		hours = 0.001 // küçük bir epsilon ile bölmeyi güvenli hale getir
	}

	speed := distKm / hours // km/saat

	if speed > 1000 {
		// İmkansız seyahat: kullanıcıyı shadowban et
		_, err := s.db.Exec(ctx, `
			UPDATE users
			SET is_shadowbanned = TRUE
			WHERE id = $1
		`, userID)
		if err != nil {
			return fmt.Errorf("shadowban user: %w", err)
		}
		return fmt.Errorf("impossible travel detected, user shadowbanned")
	}

	// Güvenli hız: konumu güncelle
	_, err = s.db.Exec(ctx, `
		UPDATE profiles
		SET lat = $2, lon = $3,
		    location_updated_at = $4
		WHERE user_id = $1
	`, userID, lat, lon, now)
	if err != nil {
		return fmt.Errorf("update location: %w", err)
	}

	return nil
}

