package config

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

func loadEnvVariableOrSecret(ctx context.Context, envVariableNamePrefix string) (string, error) {
	botTokenFromEnv := os.Getenv(envVariableNamePrefix)
	if botTokenFromEnv != "" {
		return botTokenFromEnv, nil
	}

	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}
	client := secretsmanager.NewFromConfig(cfg)

	secretId := os.Getenv(envVariableNamePrefix + "_SECRET_ID")
	if secretId == "" {
		return "", fmt.Errorf("Neither %s_SECRET_ID nor %s environment variables were set", envVariableNamePrefix, envVariableNamePrefix)
	}
	resp, err := client.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretId),
	})
	if err != nil {
		log.Fatal(err)
	}

	return *resp.SecretString, nil
}
