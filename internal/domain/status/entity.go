package status

import "time"

type Status struct {
	ID        string
	UserID    string
	Content   string
	Lat       float64
	Lon       float64
	ExpiresAt time.Time
	IsActive  bool
	CreatedAt time.Time
	DistanceKm *float64
}

type AcceptanceResult struct {
	StatusID   string
	OwnerID    string
	RequesterID string
}

