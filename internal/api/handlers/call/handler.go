package call

import (
	"encoding/json"
	"net/http"

	"github.com/example/datenow/internal/middleware"
	"github.com/example/datenow/internal/service"
	ws "github.com/example/datenow/internal/websocket"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	callService *service.CallService
	hub         *ws.Hub
}

func NewHandler(callService *service.CallService, hub *ws.Hub) *Handler {
	return &Handler{
		callService: callService,
		hub:         hub,
	}
}

type initiateRequest struct {
	MatchID string `json:"match_id" binding:"required,uuid4"`
}

type acceptRequest struct {
	MatchID string `json:"match_id" binding:"required,uuid4"`
}

func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/initiate", h.Initiate)
	rg.POST("/accept", h.Accept)
}

func (h *Handler) Initiate(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	callerID, _ := userIDVal.(string)

	var req initiateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload", "details": err.Error()})
		return
	}

	res, err := h.callService.InitiateCall(c.Request.Context(), callerID, req.MatchID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// WebSocket üzerinden aranan kişiye "incoming_call" sinyali gönder.
	payload := map[string]any{
		"type":     "incoming_call",
		"match_id": res.MatchID,
		"from_id":  callerID,
	}
	if data, err := json.Marshal(payload); err == nil {
		h.hub.SendToUser(res.CalleeID, data)
	}

	c.JSON(http.StatusOK, gin.H{"status": "call_requested"})
}

func (h *Handler) Accept(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	accepterID, _ := userIDVal.(string)

	var req acceptRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload", "details": err.Error()})
		return
	}

	result, err := h.callService.AcceptCall(c.Request.Context(), accepterID, req.MatchID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Her iki tarafa da "call_accepted" sinyalini gönder.
	payload := map[string]any{
		"type":         "call_accepted",
		"match_id":     req.MatchID,
		"channel_name": result.ChannelName,
	}
	if data, err := json.Marshal(payload); err == nil {
		h.hub.SendToUser(result.CallerID, data)
		h.hub.SendToUser(result.CalleeID, data)
	}

	c.JSON(http.StatusOK, gin.H{
		"channel_name": result.ChannelName,
		// Tokenlar client tarafında saklanacak, provider'a iletilecek:
		"rtc": map[string]string{
			"caller_token": result.CallerToken,
			"callee_token": result.CalleeToken,
		},
	})
}

