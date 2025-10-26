package filter

import (
	"context"
	"log"
	"os"
	"os/exec"
	"syscall"
	"time"
)

func executeInSandbox(ctx context.Context, shellcode []byte, flag string) (returnCode int, err error) {
	executablePath := os.Getenv("CHALLENGE_BINARY_PATH")
	if executablePath == "" {
		executablePath = "/app/challenge"
	}
	cmd := exec.Command(executablePath, flag)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}

	stdin, err := cmd.StdinPipe()
	if err != nil {
		log.Printf("Failed to open an stdin pipe: %v", err)
		return -1, err
	}
	defer stdin.Close()

	if err := cmd.Start(); err != nil {
		log.Printf("Failed to execute a challenge file: %v", err)
		return -1, err
	}
	done := make(chan any, 1)
	go func() {
		cmd.Wait()
		done <- nil
	}()

	if _, err := stdin.Write(shellcode); err != nil {
		log.Printf("Failed to write shellcode to stdin: %v", err)
		return -1, err
	}

	select {
	case <-done:
		return cmd.ProcessState.ExitCode(), nil
	case <-time.After(time.Second):
	case <-ctx.Done():
	}
	syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
	return -1, errExecutionTimeout
}
