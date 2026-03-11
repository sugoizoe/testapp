package middleware

import (
	"compress/gzip"
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// OuroborosTrap, honeypot/tarpit için kullanılabilecek ağır JSON bombasını
// streaming biçiminde üretir. Amaç bizim RAM'i değil, saldırganın tarafını şişirmek.
//
// Kullanım:
//   router.GET("/api/v1/evil", OuroborosTrap())

func OuroborosTrap() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Content-Type", "application/json")
		c.Header("Content-Encoding", "gzip")
		c.Status(http.StatusOK)

		pr, pw := io.Pipe()
		gw := gzip.NewWriter(pw)

		go func() {
			defer pw.Close()
			defer gw.Close()

			// Büyük ama kontrollü, derin iç içe geçmiş bir JSON:
			// {"D":{"D":{... n kez ...{"msg": "..."} } } }

			const depth = 5000

			// Açılış
			io.WriteString(gw, `{"D":`)
			for i := 0; i < depth-1; i++ {
				io.WriteString(gw, `{"D":`)
			}

			// En derin düğümde ASCII art + mesaj
			io.WriteString(gw, `{"msg":"`)
			io.WriteString(gw, asciiTaunt())
			io.WriteString(gw, `"}`)

			// Kapatmalar
			for i := 0; i < depth; i++ {
				io.WriteString(gw, "}")
			}
		}()

		// Yavaş yavaş stream ederek karşı tarafın bağlantısını meşgul et.
		buf := make([]byte, 32*1024)
		for {
			n, err := pr.Read(buf)
			if n > 0 {
				if _, werr := c.Writer.Write(buf[:n]); werr != nil {
					return
				}
				// Hafif gecikme: tarpit etkisini artırmak için
				time.Sleep(50 * time.Millisecond)
			}
			if err != nil {
				break
			}
		}
	}
}

func asciiTaunt() string {
	// Basit bir "D" harfi ve mesaj
	return `
██████╗ 
██╔══██╗
██║  ██║
██║  ██║
██████╔╝
╚═════╝ 

Nice try. Welcome to Datenow.`
}

