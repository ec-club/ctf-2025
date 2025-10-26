package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/ec-club/2025/round-2/misc/alphabet/challenge/audio"
	"github.com/ec-club/2025/round-2/misc/alphabet/challenge/flag"
	"github.com/martinlindhe/base36"
)

func main() {
	flag := flag.GetFlag()
	encoded := strings.ToLower(base36.EncodeBytes([]byte(flag)))
	for len(encoded) < 10000 {
		encoded = strings.ToLower(base36.EncodeBytes([]byte(encoded)))
	}
	data := audio.GenerateAudioFile(encoded)
	os.WriteFile("challenge.wav", data, 0644)
	fmt.Printf("Encoded data: %s\n", encoded)
	fmt.Printf("Generated a flag: %s\n", flag)
}
