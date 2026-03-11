package rtc

// Bu dosya, Agora/WebRTC sağlayıcısı ile entegrasyonda
// P2P bağlantıları devre dışı bırakıp yalnızca TURN relay kullanmaya yönelik
// konfigürasyon iskeletini temsil eder.

type AgoraProviderConfig struct {
	AppID        string
	AppSecret    string
	ForceRelay   bool
	TURNURLs     []string
	TURNUsername string
	TURNPassword string
}

type AgoraProvider struct {
	cfg AgoraProviderConfig
}

func NewAgoraProvider(cfg AgoraProviderConfig) *AgoraProvider {
	return &AgoraProvider{cfg: cfg}
}

// BuildConnectionConfig, istemci tarafında sadece TURN (relay) üzerinden
// bağlantı kurulmasını zorlayacak ICE server listesini döndürür.
// Gerçek uygulamada bu yapı JSON olarak frontende gönderilir.
func (p *AgoraProvider) BuildConnectionConfig() map[string]any {
	iceServers := []map[string]any{
		{
			"urls":     p.cfg.TURNURLs,
			"username": p.cfg.TURNUsername,
			"credential": p.cfg.TURNPassword,
		},
	}

	return map[string]any{
			"iceTransportPolicy": "relay", // P2P devre dışı, sadece relay (TURN)
			"iceServers":         iceServers,
	}
}

