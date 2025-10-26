package server

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"net"
	"os/exec"
	"syscall"
	"time"

	"github.com/ec-club/ctf-2025/challenges/round-1/misc/blind-goat/flag"
	"golang.org/x/crypto/ssh"
)

func runFlagServerHandler(l net.Listener, sessionID []byte, peerAddress net.Addr, done chan interface{}) {
	go func() {
		flag := flag.GetFlag(sessionID)
		log.Printf("Generated flag %s for %s", flag, peerAddress)
		for {
			conn, err := l.Accept()
			if err != nil {
				return
			}
			go func() {
				defer conn.Close()
				conn.Write([]byte(flag))
			}()
		}
	}()
	<-done
	l.Close()
}

func connect(channel ssh.Channel, peerAddr net.Addr, sessionID []byte) {
	defer channel.Close()

	flagServerDone := make(chan any, 1)
	l, err := net.Listen("tcp", ":0")
	if err != nil {
		log.Printf("Failed to start flag server: %v", err)
		io.WriteString(channel, "Failed to spawn a flag server, please create a ticket in Discord.\n")
		return
	}
	go runFlagServerHandler(l, sessionID, peerAddr, flagServerDone)

	fmt.Fprintf(channel, "Welcome to the shell, now grab your flag on %d!\n", l.Addr().(*net.TCPAddr).Port)
	scanner := bufio.NewScanner(channel)
	for {
		io.WriteString(channel, "$ ")
		if !scanner.Scan() {
			break
		}
		line := scanner.Text()

		cmd := exec.Command("sh", "-c", line)
		cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
		cmd.Start()
		done := make(chan any, 1)
		go func() {
			cmd.Wait()
			done <- nil
		}()
		select {
		case <-done:
			fmt.Fprintf(channel, "%d\n", cmd.ProcessState.ExitCode())
		case <-time.After(time.Second):
			syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
			io.WriteString(channel, "six seven!\n")
		}
	}

	flagServerDone <- nil
}
