package api

import (
	"net/http"
	"time"

	authHandlerPkg "github.com/example/datenow/internal/api/handlers/auth"
	discoveryHandlerPkg "github.com/example/datenow/internal/api/handlers/discovery"
	"github.com/example/datenow/internal/api/validators"
	"github.com/example/datenow/internal/middleware"
	"github.com/example/datenow/internal/repository/postgres"
	"github.com/example/datenow/internal/service"
	ws "github.com/example/datenow/internal/websocket"
	"github.com/example/datenow/pkg/rtc"
	"github.com/example/datenow/pkg/security"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/jackc/pgx/v5/pgxpool"
)

// SetupRouter örneği, ofensif güvenlik katmanlarının Discovery ve Auth endpoint'lerine
// nasıl uygulanacağını gösterir. main.go içinde birebir kullanılmak zorunda değildir;
// referans mimari olarak bırakılmıştır.
func SetupRouter(db *pgxpool.Pool, rtcService *rtc.Service) *gin.Engine {
	jwtCfg := security.JWTConfig{
		AccessSecret:    []byte("dummy"),
		RefreshSecret:   []byte("dummy"),
		AccessTokenTTL:  15 * time.Minute,
		RefreshTokenTTL: 7 * 24 * time.Hour,
		Issuer:          "datenow-api",
	}
	jwtManager := security.NewJWTManager(jwtCfg)

	v := validator.New()
	_ = validators.RegisterCustomValidators(v)

	authService := service.NewAuthService(db, security.DefaultArgon2Config(), jwtManager)
	authHandler := authHandlerPkg.NewHandler(authService, v)

	discoveryRepo := postgres.NewDiscoveryRepository(db)
	discoveryService := service.NewDiscoveryService(discoveryRepo)
	discoveryHandler := discoveryHandlerPkg.NewHandler(discoveryService, v)

	hub := ws.NewHub()
	_ = hub // burada sadece referans amaçlı

	authMW := middleware.NewAuthMiddleware(jwtManager)
	deviceAttestor := security.NewDeviceAttestor()
	deviceMW := middleware.NewDeviceAttestationMiddleware(deviceAttestor)

	router := gin.New()
	router.Use(gin.Recovery())

	apiGroup := router.Group("/api/v1")

	// Proof-of-Work ve JA3 guard, Auth uçlarının önüne konulabilir.
	authGroup := apiGroup.Group("/auth")
	{
		authGroup.Use(middleware.JA3FingerprintGuard())
		authGroup.POST("/login", authHandler.Login)
		authGroup.POST("/register", authHandler.Register)
	}

	// Discovery: JA3 guard + tarpit, botlara karşı sahte veri dönebilir.
	discoveryGroup := apiGroup.Group("/discovery")
	{
		discoveryGroup.Use(authMW.Handler(), deviceMW.Handler(), middleware.JA3FingerprintGuard(), middleware.TarpitMiddleware())
		discoveryHandler.RegisterRoutes(discoveryGroup)
	}

	// Örnek healthcheck
	router.GET("/healthz", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	return router
}

