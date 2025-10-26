package main

import (
	"context"
	"log"
	"os"
	"os/signal"

	"github.com/ec-club/2025/round-2/web/romance-scam/backend/tgbot"
	"github.com/ec-club/2025/round-2/web/romance-scam/backend/web"
	"github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
)

func main() {
	if os.Getenv("FLAG") == "" {
		log.Fatal("FLAG environment variable was not set.")
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	if err := tgbot.Run(ctx); err != nil {
		log.Fatal(err)
	}

	app := fiber.New(fiber.Config{EnableTrustedProxyCheck: true, TrustedProxies: []string{"*"}})
	app.Get("/login", websocket.New(web.HandleLogin))
	go func() {
		if err := app.Listen(":8000"); err != nil {
			log.Fatalf("Failed to listen: %v", err)
		}
	}()

	<-ctx.Done()
	if err := app.Shutdown(); err != nil {
		log.Fatalf("Failed to shutdown a server: %v", err)
	}
}
