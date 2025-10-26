package server

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"log"

	"golang.org/x/crypto/ssh"
)

func prepareServerConfig() *ssh.ServerConfig {
	config := &ssh.ServerConfig{
		NoClientAuth: true,
	}

	hostKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		log.Fatalf("Failed to generate ECDSA key: %v", err)
	}
	hostKeySigner, err := ssh.NewSignerFromKey(hostKey)
	if err != nil {
		log.Fatalf("Failed to create an SSH signer: %v", err)
	}
	config.AddHostKey(hostKeySigner)

	return config
}
