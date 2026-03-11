package chat

import (
	"net/http"

	"github.com/example/datenow/internal/domain/chat"
	"github.com/example/datenow/internal/middleware"
	"github.com/example/datenow/internal/service"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	chatService *service.ChatService
}

func NewHandler(chatService *service.ChatService) *Handler {
	return &Handler{chatService: chatService}
}

func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/send-date-request", h.SendDateRequest)
}

func (h *Handler) SendDateRequest(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	senderID, _ := userIDVal.(string)

	var req chat.SendDateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload", "details": err.Error()})
		return
	}

	if err := h.chatService.SendDateRequest(c.Request.Context(), senderID, req); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "sent"})
}

