package flag

import (
	"os"
	"strings"

	"github.com/sixafter/nanoid"
)

func GetFlag() string {
	flagTemplate := os.Getenv("FLAG")
	flag := strings.Replace(flagTemplate, "$1", nanoid.MustWithLength(0xb).String(), 1)
	flag = strings.Replace(flag, "$2", nanoid.MustWithLength(0xa).String(), 1)
	flag = strings.Replace(flag, "$3", nanoid.MustWithLength(0xd).String(), 1)
	return flag
}
