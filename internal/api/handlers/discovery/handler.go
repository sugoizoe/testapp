package discovery

import (
	"net/http"
	"strconv"

	"github.com/example/datenow/internal/domain/match"
	"github.com/example/datenow/internal/middleware"
	"github.com/example/datenow/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
)

type Handler struct {
	discoveryService *service.DiscoveryService
	validator        *validator.Validate
}

func NewHandler(discoveryService *service.DiscoveryService, v *validator.Validate) *Handler {
	return &Handler{
		discoveryService: discoveryService,
		validator:        v,
	}
}

func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.GET("/nearby", h.GetNearby)
	rg.POST("/swipe", h.Swipe)
}

func (h *Handler) GetNearby(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	userID, _ := userIDVal.(string)

	radiusStr := c.DefaultQuery("radius_km", "10")
	limitStr := c.DefaultQuery("limit", "50")

	radiusKm, err := strconv.ParseFloat(radiusStr, 64)
	if err != nil {
		radiusKm = 10
	}
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		limit = 50
	}

	profiles, err := h.discoveryService.GetNearbyProfiles(c.Request.Context(), userID, radiusKm, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, profiles)
}

func (h *Handler) Swipe(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	userID, _ := userIDVal.(string)

	var req match.SwipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload", "details": err.Error()})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "validation failed", "details": err.Error()})
		return
	}

	result, err := h.discoveryService.Swipe(c.Request.Context(), userID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	resp := gin.H{
		"is_match": false,
	}
	if result != nil && result.IsMatch && result.MatchID != nil {
		resp["is_match"] = true
		resp["match_id"] = *result.MatchID
		resp["message"] = "Görüntülü konuşmaya hazırsınız"
	}

	c.JSON(http.StatusOK, resp)
}

