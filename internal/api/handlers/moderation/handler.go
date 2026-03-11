package moderation

import (
	"net/http"

	"github.com/example/datenow/internal/middleware"
	"github.com/example/datenow/internal/service"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	moderation *service.ModerationService
}

func NewHandler(moderation *service.ModerationService) *Handler {
	return &Handler{moderation: moderation}
}

type reportRequest struct {
	Reason      string  `json:"reason" binding:"required"` // NUDITY, HARASSMENT, SPAM, SCAM
	Description string  `json:"description"`
	ContextID   *string `json:"context_id"`
}

func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/users/:id/block", h.BlockUser)
	rg.POST("/users/:id/report", h.ReportUser)
}

func (h *Handler) BlockUser(c *gin.Context) {
	currentUserVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	blockerID, _ := currentUserVal.(string)
	blockedID := c.Param("id")
	if blockedID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing user id"})
		return
	}

	if err := h.moderation.BlockUser(c.Request.Context(), blockerID, blockedID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "blocked"})
}

func (h *Handler) ReportUser(c *gin.Context) {
	currentUserVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	reporterID, _ := currentUserVal.(string)
	reportedID := c.Param("id")
	if reportedID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing user id"})
		return
	}

	var req reportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload", "details": err.Error()})
		return
	}

	if err := h.moderation.ReportUser(c.Request.Context(), service.ReportRequest{
		ReporterID:  reporterID,
		ReportedID:  reportedID,
		Reason:      req.Reason,
		Description: req.Description,
		ContextID:   req.ContextID,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"status": "reported"})
}

