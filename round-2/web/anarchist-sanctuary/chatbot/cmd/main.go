package main

import (
	"context"
	"log"
	"os"
	"os/signal"

	"github.com/ec-club/2025/round-2/web/anarchist-sanctuary/backend/tgbot"
)

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	if err := tgbot.Run(ctx); err != nil {
		log.Fatal(err)
	}
	log.Printf("✈️ Telegram bot has started!")
	<-ctx.Done()
}
