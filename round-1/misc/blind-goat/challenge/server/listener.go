package server

import (
	"crypto/rand"
	"encoding/binary"
	"fmt"
	"io"
	"log"
	"net"
	"sync"
	"time"

	"golang.org/x/crypto/ssh"
)

func ListenAndServe(listenAddr string) error {
	listener, err := net.Listen("tcp", listenAddr)
	if err != nil {
		return err
	}
	defer listener.Close()
	log.Printf("Listening on %s…", listenAddr)

	config := prepareServerConfig()
	for {
		nConn, err := listener.Accept()
		if err != nil {
			log.Printf("Failed to accept incoming connection: %s", err)
			continue
		}

		var wg sync.WaitGroup
		go func(nConn net.Conn) {
			sshConn, chans, reqs, err := ssh.NewServerConn(nConn, config)
			if err != nil {
				log.Printf("Failed to perform SSH handshake: %s", err)
				nConn.Close()
				return
			}
			defer sshConn.Close()
			go ssh.DiscardRequests(reqs)

			connectionChan := make(chan ssh.Channel, 1)
			var pendingPort uint16 = 0xFFFF
			if err = binary.Read(rand.Reader, binary.BigEndian, &pendingPort); err != nil {
				log.Printf("Failed to generate random port: %v", err)
				return
			}

			portSent := false
			for newChannel := range chans {
				if newChannel.ChannelType() == "session" {
					channel, requests, err := newChannel.Accept()
					if err != nil {
						continue
					}
					go ssh.DiscardRequests(requests)
					if portSent {
						io.WriteString(channel, "I've already told you the port!\n")
						channel.Close()
						continue
					}

					io.WriteString(channel, fmt.Sprintf("Welcome to Blind Goat challenge! I will come back to you on port %d in 5 seconds.\n", pendingPort))
					wg.Go(func() {
						select {
						case conn := <-connectionChan:
							connect(conn, sshConn.RemoteAddr(), sshConn.SessionID())
						case <-time.After(5 * time.Second):
						}
					})
					channel.Close()
					portSent = true
					continue
				}
				if newChannel.ChannelType() != "forwarded-tcpip" {
					newChannel.Reject(ssh.UnknownChannelType, "https://youtu.be/IBfECHr-gtI")
					continue
				}
				wg.Go(func() {
					handleForwardingChannel(newChannel, pendingPort, connectionChan)
				})
				break
			}
			wg.Wait()
		}(nConn)
	}
}
