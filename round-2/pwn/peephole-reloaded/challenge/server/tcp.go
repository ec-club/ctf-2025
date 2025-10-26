package server

import (
	"context"
	"log"
	"net"
)

const TCP_GREETING = `
                            .__           .__
______   ____   ____ ______ |  |__   ____ |  |   ____
\____ \_/ __ \_/ __ \\____ \|  |  \ /  _ \|  | _/ __ \
|  |_> >  ___/\  ___/|  |_> >   Y  (  <_> )  |_\  ___/
|   __/ \___  >\___  >   __/|___|  /\____/|____/\___  >
|__|        \/     \/|__|        \/                 \/
               .__                    .___         .___
_______   ____ |  |   _________     __| _/____   __| _/
\_  __ \_/ __ \|  |  /  _ \__  \   / __ |/ __ \ / __ |
 |  | \/\  ___/|  |_(  <_> ) __ \_/ /_/ \  ___// /_/ |
 |__|    \___  >____/\____(____  /\____ |\___  >____ |
             \/                \/      \/    \/     \/

This challenge is powered by the newest protocol that lies at the roots for h3 protocol.
Just ask your LLM or something, he knows. Connect at the port 8443 :)

Quick note: this world has been testing your knowledge about multiplexing, so be prepared!
You need to reuse the connection for multiple requests, otherwise, it won't work. This challenge
is the quintessence of PaaS, Peephole and different SSH challenges, just in a different package 📦

To start, just create a read stream. Only one rule: NO DUPLEX STREAMS ALLOWED! I will kick you out!

gtg, bye! Six seeeeeven 🐦‍🔥🐦‍🔥
`

func handleTCPConnection(conn net.Conn) {
	defer conn.Close()
	conn.Write([]byte(TCP_GREETING))
}

func ServeTCP(ctx context.Context, port string) error {
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		return err
	}
	go func() {
		<-ctx.Done()
		listener.Close()
	}()

	log.Printf("🚀 Listening on TCP port %s", port)
	go func() {
		for {
			conn, err := listener.Accept()
			if err != nil {
				select {
				case <-ctx.Done():
					return
				default:
					log.Printf("Failed to accept TCP connection: %v", err)
					continue
				}
			}
			go handleTCPConnection(conn)
		}
	}()
	return nil
}
