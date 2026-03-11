package chat

type SendDateRequest struct {
	MatchID string                 `json:"match_id" binding:"required,uuid4"`
	Content map[string]interface{} `json:"content" binding:"required"` // Örn: {"proposed_time": "...", "note": "..."}
}

