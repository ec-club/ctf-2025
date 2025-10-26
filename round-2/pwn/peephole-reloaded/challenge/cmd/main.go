package main

import (
	"context"
	"log"
	"os"
	"os/signal"

	"github.com/ec-club/2025/round-2/pwn/peephole-reloaded/challenge/server"
)

func main() {
	if os.Getenv("FLAG") == "" {
		log.Fatal("FLAG environment variable was not provided")
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8443"
	}

	if err := server.ServeTCP(ctx, port); err != nil {
		log.Fatalf("Failed to start TCP server: %v", err)
	}

	certStorePath := os.Getenv("CERT_STORE_PATH")
	if certStorePath == "" {
		certStorePath = "certstore.json"
	}
	cert, err := server.ParseCertificateStore(certStorePath)
	if err != nil {
		log.Fatalf("Failed to parse certificate store: %v", err)
	}
	if err := server.ServeQUIC(ctx, port, cert); err != nil {
		log.Fatalf("Failed to start QUIC server: %v", err)
	}
	<-ctx.Done()
}
