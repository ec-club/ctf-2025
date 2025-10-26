package flag

import (
	"encoding/base64"
	"os"
	"strings"

	"github.com/sixafter/nanoid"
)

func deriveSignature(sessionID []byte) string {
	signature := base64.URLEncoding.EncodeToString(sessionID)
	signature = strings.TrimRight(signature, "=")
	return signature
}

func GetFlag(sessionID []byte) string {
	flagTemplate := os.Getenv("FLAG")
	signature := deriveSignature(sessionID)
	flag := strings.Replace(flagTemplate, "$1", signature, 1)
	flag = strings.Replace(flag, "$2", nanoid.MustWithLength(32).String(), 1)
	return flag
}
