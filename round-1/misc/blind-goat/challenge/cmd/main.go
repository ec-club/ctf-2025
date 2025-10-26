package main

import (
	"log"
	"os"

	"github.com/ec-club/ctf-2025/challenges/round-1/misc/blind-goat/server"
)

func main() {
	listenAddr := os.Getenv("LISTEN_ADDR")
	if listenAddr == "" {
		listenAddr = "0.0.0.0:2222"
	}
	if err := server.ListenAndServe(listenAddr); err != nil {
		log.Fatalf("Failed to start the server: %s", err)
	}
}
