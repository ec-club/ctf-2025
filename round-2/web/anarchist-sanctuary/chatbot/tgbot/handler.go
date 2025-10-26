package tgbot

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"

	"github.com/go-telegram/bot"
	"github.com/go-telegram/bot/models"
)

func handler(ctx context.Context, b *bot.Bot, update *models.Update) {
	if stateManager.IsRejected(update.Message.From.ID) {
		b.SendMessage(ctx, &bot.SendMessageParams{
			ChatID: update.Message.Chat.ID,
			Text:   "nah bro ur not welcome here.",
		})
		return
	}
	if stateManager.IsApproved(update.Message.From.ID) {
		username := update.Message.Text
		b.SendMessage(ctx, &bot.SendMessageParams{
			ChatID: update.Message.Chat.ID,
			Text:   "aight lemme check this rq",
		})
		u := url.URL{
			Scheme: "http",
			Host:   os.Getenv("BOT_ADDRESS"),
			Path:   fmt.Sprintf("/visit/%s", url.PathEscape(username)),
		}
		q := u.Query()
		q.Set("x-requester", fmt.Sprintf("%d", update.Message.From.ID))
		u.RawQuery = q.Encode()
		go func() {
			_, err := http.Get(u.String())
			if err != nil {
				log.Printf("Error visiting user %s: %v", username, err)
			}
		}()
		return
	}
	if update.Message.Text != "" {
		handleTextMessage(ctx, b, update)
		return
	}
}
