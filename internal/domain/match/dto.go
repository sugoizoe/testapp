package match

type SwipeRequest struct {
	TargetID string `json:"target_id" binding:"required,uuid4" validate:"required,uuid4"`
	Action   string `json:"action" binding:"required,oneof=like dislike" validate:"required,oneof=like dislike"`
}

type NearbyProfileResponse struct {
	UserID     string   `json:"user_id"`
	FullName   string   `json:"full_name"`
	Age        int      `json:"age"`
	Gender     string   `json:"gender"`
	Bio        string   `json:"bio,omitempty"`
	City       string   `json:"city,omitempty"`
	Country    string   `json:"country,omitempty"`
	DistanceKm float64  `json:"distance_km"`
	Attributes any      `json:"attributes,omitempty"`
}

