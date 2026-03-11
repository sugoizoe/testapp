package main

import (
	"context"
	"crypto/tls"
	"log"
	"net/http"
	"os"
	"time"

	authHandlerPkg "github.com/example/datenow/internal/api/handlers/auth"
	billingHandlerPkg "github.com/example/datenow/internal/api/handlers/billing"
	callHandlerPkg "github.com/example/datenow/internal/api/handlers/call"
	chatHandlerPkg "github.com/example/datenow/internal/api/handlers/chat"
	moderationHandlerPkg "github.com/example/datenow/internal/api/handlers/moderation"
	notificationHandlerPkg "github.com/example/datenow/internal/api/handlers/notification"
	statusHandlerPkg "github.com/example/datenow/internal/api/handlers"
	webhookHandlerPkg "github.com/example/datenow/internal/api/handlers/webhook"
	discoveryHandlerPkg "github.com/example/datenow/internal/api/handlers/discovery"
	"github.com/example/datenow/internal/api/validators"
	"github.com/example/datenow/internal/middleware"
	"github.com/example/datenow/internal/repository/postgres"
	"github.com/example/datenow/internal/service"
	billingSvc "github.com/example/datenow/internal/service/billing"
	ws "github.com/example/datenow/internal/websocket"
	"github.com/example/datenow/pkg/rtc"
	"github.com/example/datenow/pkg/security"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://datenow_user:supersecurepassword@localhost:5432/datenow?sslmode=disable"
	}

	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("failed to connect db: %v", err)
	}
	defer pool.Close()

	v := validator.New()
	if err := validators.RegisterCustomValidators(v); err != nil {
		log.Fatalf("failed to register validators: %v", err)
	}

	argonCfg := security.DefaultArgon2Config()
	jwtCfg := security.JWTConfig{
		AccessSecret:    []byte(os.Getenv("ACCESS_TOKEN_SECRET")),
		RefreshSecret:   []byte(os.Getenv("REFRESH_TOKEN_SECRET")),
		AccessTokenTTL:  15 * time.Minute,
		RefreshTokenTTL: 7 * 24 * time.Hour,
		Issuer:          "datenow-api",
	}
	jwtManager := security.NewJWTManager(jwtCfg)

	// RTC servisi (5 dk free, 10 dk premium)
	rtcCfg := rtc.Config{
		AppID:        os.Getenv("RTC_APP_ID"),
		AppSecret:    []byte(os.Getenv("RTC_APP_SECRET")),
		TokenTTLFree:  5 * time.Minute,
		TokenTTLPrem: 10 * time.Minute,
	}
	rtcService := rtc.NewService(rtcCfg)
	deviceAttestor := security.NewDeviceAttestor()

	authService := service.NewAuthService(pool, argonCfg, jwtManager)
	authHandler := authHandlerPkg.NewHandler(authService, v)

	discoveryRepo := postgres.NewDiscoveryRepository(pool)
	discoveryService := service.NewDiscoveryService(discoveryRepo)
	discoveryHandler := discoveryHandlerPkg.NewHandler(discoveryService, v)

	callRepo := postgres.NewCallRepository(pool)
	callService := service.NewCallService(callRepo, rtcService)

	billingCfg := billingSvc.Config{
		AppleVerifyURL:  os.Getenv("APPLE_VERIFY_URL"),
		AppleSecret:     os.Getenv("APPLE_SHARED_SECRET"),
		GoogleVerifyURL: os.Getenv("GOOGLE_VERIFY_URL"),
		GoogleAPIKey:    os.Getenv("GOOGLE_API_KEY"),
	}
	billingService := billingSvc.NewService(pool, billingCfg)
	billingHandler := billingHandlerPkg.NewHandler(billingService)

	chatService := service.NewChatService(pool)
	chatHandler := chatHandlerPkg.NewHandler(chatService)

	moderationService := service.NewModerationService(pool)
	moderationHandler := moderationHandlerPkg.NewHandler(moderationService)

	fcmServerKey := os.Getenv("FCM_SERVER_KEY")
	notificationService := service.NewNotificationService(pool, fcmServerKey)
	notificationHandler := notificationHandlerPkg.NewHandler(notificationService)

	hub := ws.NewHub()

	statusRepo := postgres.NewStatusRepository(pool)
	statusHandler := statusHandlerPkg.NewStatusHandler(statusRepo, rtcService, hub)
	callHandler := callHandlerPkg.NewHandler(callService, hub)

	authMW := middleware.NewAuthMiddleware(jwtManager)
	rateLimiter := middleware.NewRateLimiter(3, 5)
	quotaMW := middleware.NewCheckCallQuotaMiddleware(pool)
	deviceMW := middleware.NewDeviceAttestationMiddleware(deviceAttestor)

	router := gin.New()
	router.Use(gin.Recovery())

	// KYC webhook'ları (auth gerektirmez, HMAC ile doğrulanır)
	webhookHandler := webhookHandlerPkg.NewHandler(pool)
	webhookGroup := router.Group("/api/v1/webhooks")
	{
		webhookHandler.RegisterRoutes(webhookGroup)
	}

	api := router.Group("/api/v1")

	authGroup := api.Group("/auth")
	{
		authGroup.POST("/register", rateLimiter.Middleware(), authHandler.Register)
		authGroup.POST("/login", rateLimiter.Middleware(), authHandler.Login)
		authGroup.POST("/refresh", authHandler.Refresh)
	}

	discoveryGroup := api.Group("/discovery")
	discoveryGroup.Use(authMW.Handler(), deviceMW.Handler())
	{
		discoveryHandler.RegisterRoutes(discoveryGroup)
	}

	callGroup := api.Group("/call")
	callGroup.Use(authMW.Handler(), quotaMW.Handler(), deviceMW.Handler())
	{
		callHandler.RegisterRoutes(callGroup)
	}

	billingGroup := api.Group("/billing")
	billingGroup.Use(authMW.Handler(), deviceMW.Handler())
	{
		billingHandler.RegisterRoutes(billingGroup)
	}

	chatGroup := api.Group("/chat")
	chatGroup.Use(authMW.Handler())
	{
		chatHandler.RegisterRoutes(chatGroup)
	}

	statusGroup := api.Group("/live")
	statusGroup.Use(authMW.Handler(), deviceMW.Handler())
	{
		statusHandler.RegisterRoutes(statusGroup)
	}

	moderationGroup := api.Group("/")
	moderationGroup.Use(authMW.Handler())
	{
		moderationHandler.RegisterRoutes(moderationGroup)
	}

	notificationGroup := api.Group("/")
	notificationGroup.Use(authMW.Handler())
	{
		notificationHandler.RegisterRoutes(notificationGroup)
	}

	// Honeypot endpoint: gerçek client'larda hiç kullanılmayan sahte route.
	honeypotMW := middleware.NewHoneypotMiddleware(pool)
	api.GET("/system/metrics-public", honeypotMW.Handler())

	protected := api.Group("/me")
	protected.Use(authMW.Handler())
	protected.GET("", func(c *gin.Context) {
		userIDVal, _ := c.Get(middleware.ContextUserIDKey)
		c.JSON(http.StatusOK, gin.H{"user_id": userIDVal})
	})

	// WebSocket endpoint (JWT query param ile doğrulama)
	router.GET("/ws", ws.ServeWS(hub, jwtManager))

	// Eğer cert.pem / key.pem varsa TLS ile, yoksa dev için plain HTTP ile başlat.
	certPath := "cert.pem"
	keyPath := "key.pem"

	if _, err := os.Stat(certPath); err == nil {
		srv := &http.Server{
			Addr:    ":8443",
			Handler: router,
			TLSConfig: &tls.Config{
				MinVersion: tls.VersionTLS13,
				MaxVersion: tls.VersionTLS13,
				CipherSuites: []uint16{
					tls.TLS_AES_128_GCM_SHA256,
					tls.TLS_AES_256_GCM_SHA384,
					tls.TLS_CHACHA20_POLY1305_SHA256,
				},
				PreferServerCipherSuites: true,
			},
			ReadTimeout:       10 * time.Second,
			ReadHeaderTimeout: 5 * time.Second,
			WriteTimeout:      10 * time.Second,
			IdleTimeout:       120 * time.Second,
		}

		log.Println("Starting HTTPS server on :8443 (TLS 1.3 only)")
		if err := srv.ListenAndServeTLS(certPath, keyPath); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	} else {
		httpSrv := &http.Server{
			Addr:              ":8080",
			Handler:           router,
			ReadTimeout:       10 * time.Second,
			ReadHeaderTimeout: 5 * time.Second,
			WriteTimeout:      10 * time.Second,
			IdleTimeout:       120 * time.Second,
		}

		log.Println("cert.pem bulunamadı, HTTPS devre dışı. HTTP server :8080 üzerinde başlatılıyor.")
		if err := httpSrv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}
}

