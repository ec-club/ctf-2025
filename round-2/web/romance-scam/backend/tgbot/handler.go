package tgbot

import (
	"context"
	"log"

	"github.com/ec-club/2025/round-2/web/romance-scam/backend/web"
	"github.com/go-telegram/bot"
	"github.com/go-telegram/bot/models"
)

func handler(ctx context.Context, b *bot.Bot, update *models.Update) {
	if stateManager.IsRejected(update.Message.From.ID) {
		b.SendMessage(ctx, &bot.SendMessageParams{
			ChatID: update.Message.Chat.ID,
			Text:   "I'm not in the mood to chat with you… See you later!",
		})
		return
	}
	if stateManager.IsApproved(update.Message.From.ID) {
		if update.Message == nil || len(update.Message.Photo) == 0 {
			b.SendMessage(ctx, &bot.SendMessageParams{
				ChatID: update.Message.Chat.ID,
				Text:   "Hey, I was expecting a photo from you. Please send me one so we can continue our chat!",
			})
			return
		} else {
			photo := update.Message.Photo[0] // Get the largest photo
			file, err := b.GetFile(ctx, &bot.GetFileParams{
				FileID: photo.FileID,
			})
			if err != nil {
				b.SendMessage(ctx, &bot.SendMessageParams{
					ChatID: update.Message.Chat.ID,
					Text:   "Hey bestie, was that a photo? It doesn't show up on my phone 😢 Could you try sending it again?",
				})
				return
			}

			url := b.FileDownloadLink(file)
			if err := web.ApproveQRCode(url); err != nil {
				log.Printf("Failed to approve a QR code: %v", err)
				b.SendMessage(ctx, &bot.SendMessageParams{
					ChatID: update.Message.Chat.ID,
					Text:   "What's that bestie? I couldn't read it. Could you send me a clearer QR code so I can read it with my phone?",
				})
			} else {
				b.SendMessage(ctx, &bot.SendMessageParams{
					ChatID: update.Message.Chat.ID,
					Text:   "Aww, do you want to see a secret on my fan website? I've signed you in as my special bestie! 💖",
				})
			}
			return
		}
	}
	if update.Message == nil || update.Message.Text == "" {
		b.SendMessage(ctx, &bot.SendMessageParams{
			ChatID: update.Message.Chat.ID,
			Text:   "Hey, I'm sorry but I can only chat via text messages. Please send me a text so we can continue our conversation!",
		})
		return
	}
	if update.Message.Text != "" {
		handleTextMessage(ctx, b, update)
		return
	}
}
