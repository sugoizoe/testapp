package middleware

import (
	"net/http"

	"github.com/example/datenow/pkg/security"

	"github.com/gin-gonic/gin"
)

// DeviceAttestationMiddleware: hassas endpointlerde cihazın bütünlüğünü doğrular.

type DeviceAttestationMiddleware struct {
	attestor *security.DeviceAttestor
}

func NewDeviceAttestationMiddleware(attestor *security.DeviceAttestor) *DeviceAttestationMiddleware {
	return &DeviceAttestationMiddleware{attestor: attestor}
}

func (m *DeviceAttestationMiddleware) Handler() gin.HandlerFunc {
	return func(c *gin.Context) {
		platform := c.GetHeader("X-Device-Platform") // "android" veya "ios"
		token := c.GetHeader("X-Device-Attestation")
		if platform == "" || token == "" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "device attestation required"})
			return
		}

		var ok bool
		var err error

		switch platform {
		case "android":
			ok, err = m.attestor.VerifyAndroidIntegrity(c.Request.Context(), token)
		case "ios":
			ok, err = m.attestor.VerifyAppleAttestation(c.Request.Context(), token)
		default:
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "unsupported platform"})
			return
		}

		if err != nil || !ok {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "device attestation failed"})
			return
		}

		c.Next()
	}
}

