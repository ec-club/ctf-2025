package server

import (
	"context"
	"crypto/tls"
	"log"

	"github.com/ec-club/2025/round-2/pwn/peephole-reloaded/challenge/filter"
	"github.com/quic-go/quic-go"
)

func ServeQUIC(ctx context.Context, port string, cert *tls.Certificate) error {
	l, err := quic.ListenAddr(":"+port, &tls.Config{
		Certificates: []tls.Certificate{*cert},
	}, &quic.Config{})
	if err != nil {
		return err
	}
	go func() {
		<-ctx.Done()
		l.Close()
	}()

	log.Printf("🔥 QUIC listener started on port %s", port)
	go func() {
		for {
			sess, err := l.Accept(ctx)
			if err != nil {
				select {
				case <-ctx.Done():
					return
				default:
					log.Printf("Failed to accept QUIC session: %v", err)
					continue
				}
			}
			go filter.HandlePwnSession(sess)
		}
	}()
	return nil
}
