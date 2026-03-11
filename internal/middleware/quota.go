package middleware

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// CheckCallQuotaMiddleware: premium süresi dolmuş kullanıcılar için aylık 5 arama hakkını uygular.

type CheckCallQuotaMiddleware struct {
	db *pgxpool.Pool
}

func NewCheckCallQuotaMiddleware(db *pgxpool.Pool) *CheckCallQuotaMiddleware {
	return &CheckCallQuotaMiddleware{db: db}
}

func (m *CheckCallQuotaMiddleware) Handler() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDVal, ok := c.Get(ContextUserIDKey)
		if !ok {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			return
		}
		userID, _ := userIDVal.(string)

		ctx := c.Request.Context()
		tx, err := m.db.BeginTx(ctx, pgx.TxOptions{})
		if err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
			return
		}
		defer tx.Rollback(ctx)

		var (
			isPremium        bool
			premiumExpiresAt *time.Time
			callCount        int
			lastReset        *time.Time
		)

		err = tx.QueryRow(ctx, `
			SELECT is_premium, premium_expires_at, video_call_count, last_call_reset_date
			FROM users
			WHERE id = $1
			FOR UPDATE
		`, userID).Scan(&isPremium, &premiumExpiresAt, &callCount, &lastReset)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "user_not_found"})
			return
		}

		now := time.Now().UTC()
		// Premium süresi kontrolü
		if premiumExpiresAt != nil && premiumExpiresAt.After(now) {
			// Hala premium; kota uygulanmaz
			if err := tx.Commit(ctx); err != nil {
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
				return
			}
			c.Next()
			return
		}

		// Premium süresi bitmişse, is_premium flag'ini temizle
		if isPremium {
			isPremium = false
		}

		// Aylık reset: kayıt tarihine göre döngüsel modelin basit hali -> last_call_reset_date + 1 ay
		shouldReset := false
		if lastReset == nil {
			shouldReset = true
		} else {
			nextReset := lastReset.AddDate(0, 1, 0)
			if now.After(nextReset) {
				shouldReset = true
			}
		}

		if shouldReset {
			callCount = 0
			lastReset = &now
		}

		if callCount >= 5 {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "monthly_call_quota_exceeded"})
			return
		}

		callCount++

		_, err = tx.Exec(ctx, `
			UPDATE users
			SET
				is_premium = $1,
				video_call_count = $2,
				last_call_reset_date = $3
			WHERE id = $4
		`, isPremium, callCount, lastReset, userID)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
			return
		}

		if err := tx.Commit(ctx); err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
			return
		}

		c.Next()
	}
}

