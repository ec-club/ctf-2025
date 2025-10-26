package flag

import (
	"fmt"
	"os"
	"strings"

	"github.com/sixafter/nanoid"
)

func GetFlag() string {
	flag := os.Getenv("FLAG")
	for i := 0; i < 3; i++ {
		flag = strings.Replace(flag, fmt.Sprintf("$%d", i+1), nanoid.MustWithLength((i+1)*6).String(), 1)
	}
	return flag
}
