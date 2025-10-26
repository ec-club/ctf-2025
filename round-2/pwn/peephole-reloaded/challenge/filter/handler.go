package filter

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/quic-go/quic-go"
)

var (
	errInvalidShellcode = errors.New("invalid shellcode")
	errExecutionTimeout = errors.New("execution timeout")
	errGenericFailure   = errors.New("generic failure")
)

const GREETING = `Welcome to the Peephole Reloaded! It's nice to see you here.

This challenge is so similar to the previous one, yet so different.

You send input in one channel, and receive it in the other. You have 5 minutes to complete your task.`

func HandlePwnSession(sess *quic.Conn) {
	ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(5*time.Minute))
	defer cancel()

	log.Printf("Received a new connection from %s", sess.RemoteAddr())
	initStream, err := sess.OpenUniStream()
	if err != nil {
		sess.CloseWithError(ERROR_INVALID_STREAM, "failed to accept initial stream")
		return
	}
	if _, err = initStream.Write([]byte(GREETING)); err != nil {
		sess.CloseWithError(ERROR_GENERIC_FAILURE, "failed to send greeting")
		return
	}
	initStream.Close()

	for {
		recvStream, err := sess.AcceptUniStream(ctx)
		if err != nil {
			select {
			case <-ctx.Done():
				sess.CloseWithError(ERROR_TIMEOUT, "session timed out")
				return
			default:
				sess.CloseWithError(ERROR_INVALID_STREAM, "failed to accept stream")
				return
			}
		}
		sendStream, err := sess.OpenUniStream()
		if err != nil {
			select {
			case <-ctx.Done():
				sess.CloseWithError(ERROR_TIMEOUT, "session timed out")
				return
			default:
				sess.CloseWithError(ERROR_INVALID_STREAM, "failed to open send stream")
				return
			}
		}
		if err := handlePwnSession(&ctx, sess.RemoteAddr().String(), recvStream, sendStream); err != nil {
			if err == errInvalidShellcode {
				sess.CloseWithError(ERROR_INVALID_SHELLCODE, "invalid shellcode")
				return
			}
			if err == errExecutionTimeout {
				sess.CloseWithError(ERROR_EXECUTION_TIMEOUT, "shellcode execution timed out")
				return
			}
			sess.CloseWithError(ERROR_GENERIC_FAILURE, "failed to handle pwn session")
			return
		}
	}
}
