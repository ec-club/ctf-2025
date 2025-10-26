package web

import (
	"log"
	"time"

	"github.com/ec-club/2025/round-2/web/romance-scam/backend/flag"
	"github.com/gofiber/contrib/websocket"
)

var loginManager *LoginManager = NewLoginManager()

func HandleLogin(c *websocket.Conn) {
	defer c.Close()

	result := make(chan bool, 1)
	requestID := loginManager.RequestLogin(result)
	c.WriteJSON(map[string]any{"challenge": requestID})

	select {
	case approved := <-result:
		if !approved {
			return
		}
		result := flag.GetFlag()
		log.Printf("Releasing a flag %s to %s", result, c.IP())
		c.WriteJSON(map[string]any{"result": result})
	case <-time.After(5 * time.Minute):
		loginManager.InvalidateLoginRequest(requestID)
	}
}
