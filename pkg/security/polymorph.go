package security

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
)

// MarshalPolymorphic, verilen struct'ı alır, seed+timestamp ile HMAC-SHA256
// kullanarak JSON anahtarlarını deterministik ama dışarıdan tahmin edilemez
// şekilde maskeleyip []byte JSON olarak döner.
//
// Not: Bu fonksiyon, yalnızca map[string]any / struct benzeri "object" kökleri
// için tasarlanmıştır. Slice'lar için önce sarmalayıcı bir struct kullanmanız önerilir.
func MarshalPolymorphic(v any, seed string, timestamp int64) ([]byte, error) {
	// Önce normal JSON'a çevirerek generic map elde ediyoruz.
	raw, err := json.Marshal(v)
	if err != nil {
		return nil, fmt.Errorf("marshal input: %w", err)
	}

	var obj map[string]any
	if err := json.Unmarshal(raw, &obj); err != nil {
		return nil, fmt.Errorf("unmarshal to map: %w", err)
	}

	mutated := make(map[string]any, len(obj))
	tsStr := strconv.FormatInt(timestamp, 10)

	// Stabil sıralama (test/debug için) – operasyonel etkisi yok.
	keys := make([]string, 0, len(obj))
	for k := range obj {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	for _, k := range keys {
		newKey := maskKey(k, seed, tsStr)
		mutated[newKey] = obj[k]
	}

	out, err := json.Marshal(mutated)
	if err != nil {
		return nil, fmt.Errorf("marshal polymorphic: %w", err)
	}
	return out, nil
}

func maskKey(key, seed, ts string) string {
	h := hmac.New(sha256.New, []byte(seed))
	h.Write([]byte(ts))
	h.Write([]byte("::"))
	h.Write([]byte(key))
	sum := h.Sum(nil)
	// İlk birkaç byte'ı hex'e çevirip kısa bir prefix üretiyoruz.
	prefix := hex.EncodeToString(sum[:4]) // 8 hex karakter
	return "dn_" + prefix
}

