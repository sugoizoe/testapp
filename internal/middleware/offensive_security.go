package middleware

import (
	"crypto/tls"
	"math/rand"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// Basit bir TLS/JA3 fingerprint guard ve tarpit mekanizması.

var (
	botIPSet   = make(map[string]struct{})
	botIPMutex sync.RWMutex
)

func markIPAsBot(ip string) {
	botIPMutex.Lock()
	defer botIPMutex.Unlock()
	botIPSet[ip] = struct{}{}
}

func isIPMarkedBot(ip string) bool {
	botIPMutex.RLock()
	defer botIPMutex.RUnlock()
	_, ok := botIPSet[ip]
	return ok
}

// JA3FingerprintGuard: TLS connection state üzerinden basit fingerprint analizi yapar.
// Gerçek JA3 hesaplaması için ClientHello'a erişim gerekir; burada TLS özelliklerine
// bakarak kaba bir bot tespiti yapıyoruz ve sonucu context'e işliyoruz.
func JA3FingerprintGuard() gin.HandlerFunc {
	return func(c *gin.Context) {
		state := c.Request.TLS
		ip := clientIP(c.Request)

		if state != nil && looksLikeScriptTLS(state) {
			c.Set("is_bot", true)
			markIPAsBot(ip)
		}

		c.Next()
	}
}

// looksLikeScriptTLS: bilinen script/client TLS desenlerini kaba şekilde tespit eder.
func looksLikeScriptTLS(state *tls.ConnectionState) bool {
	// Örnek basit sezgisel kurallar:
	// - TLS1.0/1.1 kullanımı
	// - Renegotiation desteği olmayan ilkel client'lar
	// - NegotiatedProtocol boş ve ServerName boş
	if state.Version <= tls.VersionTLS11 {
		return true
	}
	if state.NegotiatedProtocol == "" && state.ServerName == "" {
		return true
	}
	return false
}

// TarpitMiddleware: bot olarak işaretlenmiş IP'ler veya shadowban'li kullanıcılar için
// yanıtı bilinçli olarak geciktirir.
//
// Not: Shadowban bilgisi AuthMiddleware sonrası, context'e "is_shadowbanned" bool değeri
// olarak yazılabilir; burada sadece o değeri okuyoruz.
func TarpitMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := clientIP(c.Request)

		isBot := isIPMarkedBot(ip)
		isShadowbanned, _ := c.Get("is_shadowbanned")

		if isBot || isShadowbanned == true {
			// 30-60 saniye arasında rastgele gecikme
			delay := time.Duration(30+rand.Intn(31)) * time.Second
			time.Sleep(delay)
		}

		c.Next()
	}
}

