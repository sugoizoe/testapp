package websocket

import (
	"log"
	"sync"
)

// ClientID olarak userID (UUID) kullanıyoruz.

type Client struct {
	UserID string
	Send   chan []byte
	Hub    *Hub
}

type Hub struct {
	mu      sync.RWMutex
	clients map[string]*Client
}

func NewHub() *Hub {
	return &Hub{
		clients: make(map[string]*Client),
	}
}

func (h *Hub) Register(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if old, ok := h.clients[c.UserID]; ok {
		close(old.Send)
	}
	h.clients[c.UserID] = c
	log.Printf("ws: user %s connected", c.UserID)
}

func (h *Hub) Unregister(userID string) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if c, ok := h.clients[userID]; ok {
		delete(h.clients, userID)
		close(c.Send)
		log.Printf("ws: user %s disconnected", userID)
	}
}

func (h *Hub) SendToUser(userID string, message []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	if c, ok := h.clients[userID]; ok {
		select {
		case c.Send <- message:
		default:
			// Kanal doluysa düşür
			go h.Unregister(userID)
		}
	}
}

