package config

import (
	"context"
	"os"
)

func LoadTelegramBotToken(ctx context.Context) (string, error) {
	return loadEnvVariableOrSecret(ctx, "TG_BOT_TOKEN")
}
func LoadDeepseekToken(ctx context.Context) (string, error) {
	return loadEnvVariableOrSecret(ctx, "DEEPSEEK_API_TOKEN")
}

func GetModelName() string {
	modelName := os.Getenv("AI_MODEL_NAME")
	if modelName == "" {
		modelName = "deepseek-chat"
	}
	return modelName
}
