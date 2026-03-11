package middleware

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

// HoneypotMiddleware: sahte endpoint'lere gelen istekleri yakalar ve kullanıcıyı shadowban eder.

type HoneypotMiddleware struct {
	db *pgxpool.Pool
}

func NewHoneypotMiddleware(db *pgxpool.Pool) *HoneypotMiddleware {
	return &HoneypotMiddleware{db: db}
}

func (m *HoneypotMiddleware) Handler() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := clientIP(c.Request)
		userIDVal, _ := c.Get(ContextUserIDKey)
		userID, _ := userIDVal.(string)

		log.Printf("honeypot hit from ip=%s user=%s path=%s", ip, userID, c.Request.URL.Path)

		if userID != "" {
			_, err := m.db.Exec(c.Request.Context(), `
				UPDATE users
				SET is_shadowbanned = TRUE
				WHERE id = $1
			`, userID)
			if err != nil {
				log.Printf("honeypot shadowban error: %v", err)
			}
		}

		c.AbortWithStatus(http.StatusNotFound)
	}
}

