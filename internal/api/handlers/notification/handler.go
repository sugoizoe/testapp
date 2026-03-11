package notification

import (
	"net/http"
	"os"

	"github.com/example/datenow/internal/middleware"
	"github.com/example/datenow/internal/service"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	notifications *service.NotificationService
}

func NewHandler(notifications *service.NotificationService) *Handler {
	return &Handler{notifications: notifications}
}

type registerTokenRequest struct {
	Token      string `json:"token" binding:"required"`
	DeviceType string `json:"device_type" binding:"required"` // ios, android, web
}

func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/notifications/token", h.RegisterToken)
}

func (h *Handler) RegisterToken(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	userID, _ := userIDVal.(string)

	var req registerTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload", "details": err.Error()})
		return
	}

	if err := h.notifications.RegisterFCMToken(c.Request.Context(), userID, req.Token, req.DeviceType); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Sağlık kontrolü için FCM server key'in set edilip edilmediğini dönebiliriz (debug amaçlı, prod'da kaldırılabilir).
	_ = os.Getenv("FCM_SERVER_KEY")

	c.JSON(http.StatusOK, gin.H{"status": "registered"})
}

