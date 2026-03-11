package webhook

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Handler struct {
	db          *pgxpool.Pool
	secretBytes []byte
}

func NewHandler(db *pgxpool.Pool) *Handler {
	secret := os.Getenv("KYC_WEBHOOK_SECRET")
	return &Handler{
		db:          db,
		secretBytes: []byte(secret),
	}
}

type kycWebhookPayload struct {
	UserID string `json:"user_id"`
	Status string `json:"status"`
}

func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/kyc", h.HandleKYC)
}

func (h *Handler) HandleKYC(c *gin.Context) {
	signature := c.GetHeader("X-Signature")
	if signature == "" || len(h.secretBytes) == 0 {
		c.AbortWithStatus(http.StatusUnauthorized)
		return
	}

	bodyBytes, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	mac := hmac.New(sha256.New, h.secretBytes)
	mac.Write(bodyBytes)
	expected := hex.EncodeToString(mac.Sum(nil))

	if !hmac.Equal([]byte(expected), []byte(signature)) {
		c.AbortWithStatus(http.StatusUnauthorized)
		return
	}

	var payload kycWebhookPayload
	if err := json.Unmarshal(bodyBytes, &payload); err != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	if payload.UserID == "" {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	// Örnek: sadece "approved" statüsünde identity doğrulamasını true yap.
	if payload.Status == "approved" {
		if _, err := h.db.Exec(c.Request.Context(), `
			UPDATE users
			SET is_identity_verified = TRUE
			WHERE id = $1
		`, payload.UserID); err != nil {
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}
	}

	c.Status(http.StatusOK)
}

