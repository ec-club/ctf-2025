package filter

import (
	"context"
	"fmt"
	"log"

	"github.com/ec-club/2025/round-2/pwn/peephole-reloaded/challenge/flag"
	"github.com/quic-go/quic-go"
)

const SHELLCODE_SIZE = 0x1000

func handlePwnSession(ctx *context.Context, peerAddress string, recv *quic.ReceiveStream, send *quic.SendStream) error {
	defer send.Close()
	if _, err := send.Write([]byte("shellcode> ")); err != nil {
		return err
	}
	shellcode := make([]byte, SHELLCODE_SIZE)
	n, err := recv.Read(shellcode)
	if err != nil {
		return err
	}
	shellcode = shellcode[:n]

	if _, ok := (*ctx).Value("flag").(string); !ok {
		newFlag := flag.GetFlag(shellcode)
		log.Printf("Generated flag %s for %s", newFlag, peerAddress)
		*ctx = context.WithValue(*ctx, "flag", newFlag)
	}

	streamID := int64(recv.StreamID())
	valid, err := verifyShellcode(peerAddress, streamID, shellcode)
	if err != nil {
		return err
	}
	if !valid {
		fmt.Fprintf(send, "invalid shellcode\n")
		return nil
	}

	exitCode, err := executeInSandbox(*ctx, shellcode, (*ctx).Value("flag").(string))
	if err != nil {
		return err
	}

	log.Printf("[%s|%d] Sending exit code %d", peerAddress, streamID, exitCode)
	if _, err := fmt.Fprintf(send, "exit code %d", exitCode); err != nil {
		return err
	}
	return nil
}
