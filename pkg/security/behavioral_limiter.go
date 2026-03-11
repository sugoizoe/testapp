package security

import (
	"sync"
	"time"
)

type BehavioralLimiter struct {
	mu        sync.Mutex
	windowSec int64
	limit     int
	entries   map[string]*behaviorEntry
}

type behaviorEntry struct {
	windowStart int64
	count       int
}

func NewBehavioralLimiter(windowSec int64, limit int) *BehavioralLimiter {
	if windowSec <= 0 {
		windowSec = 1
	}
	if limit <= 0 {
		limit = 10
	}
	return &BehavioralLimiter{
		windowSec: windowSec,
		limit:     limit,
		entries:   make(map[string]*behaviorEntry),
	}
}

// Allow kayıt altına alınan bir aksiyonun saniyelik limit içinde olup olmadığını döner.
// key tipik olarak "swipe:<userID>" veya "status_join:<userID>" gibi verilir.
func (b *BehavioralLimiter) Allow(key string) (allowed bool, shouldShadowban bool) {
	now := time.Now().Unix()
	window := now / b.windowSec

	b.mu.Lock()
	defer b.mu.Unlock()

	entry, ok := b.entries[key]
	if !ok || entry.windowStart != window {
		entry = &behaviorEntry{
			windowStart: window,
			count:       0,
		}
		b.entries[key] = entry
	}

	entry.count++
	if entry.count <= b.limit {
		return true, false
	}
	// Limit aşıldı: istek reddedilebilir ve kullanıcı shadowban için işaretlenebilir.
	return false, true
}

