package tgbot

import (
	"context"
	"os"

	"github.com/ec-club/2025/round-2/web/anarchist-sanctuary/backend/config"
	"github.com/go-telegram/bot"
	"github.com/openai/openai-go/v3"
	"github.com/openai/openai-go/v3/option"
)

func Run(ctx context.Context) error {
	opts := []bot.Option{
		bot.WithDefaultHandler(handler),
	}
	botToken, err := config.LoadTelegramBotToken(ctx)
	if err != nil {
		return err
	}
	bot, err := bot.New(botToken, opts...)
	if err != nil {
		return err
	}

	apiKey, err := config.LoadDeepseekToken(ctx)
	if err != nil {
		return err
	}
	endpointUrl := os.Getenv("AI_ENDPOINT_URL")
	if endpointUrl == "" {
		endpointUrl = "https://api.deepseek.com"
	}
	client = openai.NewClient(option.WithAPIKey(apiKey), option.WithBaseURL(endpointUrl))

	go bot.Start(ctx)
	return nil
}
