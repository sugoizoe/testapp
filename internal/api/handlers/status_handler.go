package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/example/datenow/internal/middleware"
	"github.com/example/datenow/internal/repository/postgres"
	ws "github.com/example/datenow/internal/websocket"
	"github.com/example/datenow/pkg/rtc"

	"github.com/gin-gonic/gin"
)

type StatusHandler struct {
	repo       *postgres.StatusRepository
	rtcService *rtc.Service
	hub        *ws.Hub
}

func NewStatusHandler(repo *postgres.StatusRepository, rtcService *rtc.Service, hub *ws.Hub) *StatusHandler {
	return &StatusHandler{
		repo:       repo,
		rtcService: rtcService,
		hub:        hub,
	}
}

type createStatusRequest struct {
	Content string  `json:"content" binding:"required"`
	Lat     float64 `json:"lat" binding:"required"`
	Lon     float64 `json:"lon" binding:"required"`
	TTLHours int    `json:"ttl_hours"` // opsiyonel, max 24
}

func (h *StatusHandler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/statuses", h.CreateStatus)
	rg.GET("/statuses/nearby", h.GetNearbyStatuses)
	rg.POST("/statuses/:id/join", h.JoinStatus)
	rg.POST("/statuses/requests/:request_id/accept", h.AcceptRequest)
}

func (h *StatusHandler) CreateStatus(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	userID, _ := userIDVal.(string)

	var req createStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload", "details": err.Error()})
		return
	}

	ttl := req.TTLHours
	if ttl <= 0 || ttl > 24 {
		ttl = 24
	}

	id, err := h.repo.CreateStatus(c.Request.Context(), userID, req.Content, req.Lat, req.Lon, ttl)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": id})
}

func (h *StatusHandler) GetNearbyStatuses(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	viewerID, _ := userIDVal.(string)

	latStr := c.Query("lat")
	lonStr := c.Query("lon")
	radiusStr := c.DefaultQuery("radius_km", "10")
	limitStr := c.DefaultQuery("limit", "50")

	lat, err := strconv.ParseFloat(latStr, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid lat"})
		return
	}
	lon, err := strconv.ParseFloat(lonStr, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid lon"})
		return
	}
	radiusKm, err := strconv.ParseFloat(radiusStr, 64)
	if err != nil {
		radiusKm = 10
	}
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		limit = 50
	}

	statuses, err := h.repo.GetNearbyActiveStatuses(c.Request.Context(), viewerID, lat, lon, radiusKm, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, statuses)
}

func (h *StatusHandler) JoinStatus(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	requesterID, _ := userIDVal.(string)

	statusID := c.Param("id")
	if statusID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing status id"})
		return
	}

	reqID, err := h.repo.CreateStatusRequest(c.Request.Context(), statusID, requesterID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"request_id": reqID})
}

func (h *StatusHandler) AcceptRequest(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	ownerID, _ := userIDVal.(string)

	requestID := c.Param("request_id")
	if requestID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing request id"})
		return
	}

	res, err := h.repo.AcceptRequestAndCloseStatus(c.Request.Context(), requestID, ownerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// WebRTC token üret ve her iki kullanıcıya da WebSocket ile gönder.
	channelName := "live_status_" + res.StatusID

	callerToken, _, err := h.rtcService.GenerateToken(channelName, res.OwnerID, rtc.RoleCaller, false)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "rtc token error"})
		return
	}
	calleeToken, _, err := h.rtcService.GenerateToken(channelName, res.RequesterID, rtc.RoleCallee, false)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "rtc token error"})
		return
	}

	payload := map[string]any{
		"type":          "live_call_ready",
		"status_id":     res.StatusID,
		"channel_name":  channelName,
		"owner_id":      res.OwnerID,
		"requester_id":  res.RequesterID,
		"caller_token":  callerToken,
		"callee_token":  calleeToken,
	}

	data, err := json.Marshal(payload)
	if err == nil {
		h.hub.SendToUser(res.OwnerID, data)
		h.hub.SendToUser(res.RequesterID, data)
	}

	c.JSON(http.StatusOK, gin.H{
		"status":       "accepted",
		"status_id":    res.StatusID,
		"channel_name": channelName,
	})
}

