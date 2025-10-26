package flag

import (
	"crypto/sha3"
	"encoding/base64"
	"os"
	"strings"

	"github.com/sixafter/nanoid"
)

func GetFlag(shellcode []byte) string {
	shellcodeHash := sha3.Sum224(shellcode)
	flagTemplate := os.Getenv("FLAG")
	flag := strings.Replace(flagTemplate, "$1", base64.RawURLEncoding.EncodeToString(shellcodeHash[:]), 1)
	flag = strings.Replace(flag, "$2", nanoid.MustWithLength(32).String(), 1)
	return flag
}
