package middleware

import (
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type rateLimiterConfig struct {
	RequestsPerSecond float64
	Burst             int
}

type visitor struct {
	remaining float64
	lastSeen  time.Time
}

type RateLimiter struct {
	cfg      rateLimiterConfig
	mu       sync.Mutex
	visitors map[string]*visitor
}

func NewRateLimiter(rps float64, burst int) *RateLimiter {
	return &RateLimiter{
		cfg: rateLimiterConfig{
			RequestsPerSecond: rps,
			Burst:             burst,
		},
		visitors: make(map[string]*visitor),
	}
}

func (rl *RateLimiter) getVisitor(ip string, now time.Time) *visitor {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	v, exists := rl.visitors[ip]
	if !exists {
		v = &visitor{
			remaining: float64(rl.cfg.Burst),
			lastSeen:  now,
		}
		rl.visitors[ip] = v
		return v
	}

	elapsed := now.Sub(v.lastSeen).Seconds()
	v.remaining += elapsed * rl.cfg.RequestsPerSecond
	if v.remaining > float64(rl.cfg.Burst) {
		v.remaining = float64(rl.cfg.Burst)
	}
	v.lastSeen = now
	return v
}

func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := clientIP(c.Request)
		now := time.Now()

		v := rl.getVisitor(ip, now)

		rl.mu.Lock()
		defer rl.mu.Unlock()

		if v.remaining < 1 {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{"error": "too many requests"})
			return
		}

		v.remaining -= 1
		c.Next()
	}
}

func clientIP(r *http.Request) string {
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return ip
}

