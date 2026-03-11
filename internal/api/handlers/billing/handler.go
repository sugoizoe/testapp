package billing

import (
	"net/http"

	"github.com/example/datenow/internal/middleware"
	billingSvc "github.com/example/datenow/internal/service/billing"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	service *billingSvc.Service
}

func NewHandler(service *billingSvc.Service) *Handler {
	return &Handler{service: service}
}

type verifyReceiptRequest struct {
	Provider    string `json:"provider" binding:"required,oneof=apple google"`
	Receipt     string `json:"receipt" binding:"required"`
	Currency    string `json:"currency" binding:"required"`
	AmountCents int    `json:"amount_cents" binding:"required,min=1"`
}

func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/verify-receipt", h.VerifyReceipt)
}

func (h *Handler) VerifyReceipt(c *gin.Context) {
	userIDVal, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	userID, _ := userIDVal.(string)

	var req verifyReceiptRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload", "details": err.Error()})
		return
	}

	vReq := billingSvc.VerifyRequest{
		Provider:    billingSvc.Provider(req.Provider),
		Receipt:     req.Receipt,
		Currency:    req.Currency,
		AmountCents: req.AmountCents,
	}

	result, err := h.service.VerifyAndActivateSubscription(c.Request.Context(), userID, vReq)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":        "success",
		"purchased_at":  result.PurchasedAt,
		"expires_at":    result.ExpiresAt,
		"subscription":  req.Provider,
		"currency":      req.Currency,
		"amount_cents":  req.AmountCents,
		"billing_status": result.Status,
	})
}

