package audio

import (
	"fmt"
	"log"
	"os"
)

var (
	dictionary          = "abcdefghijklmnopqrstuvwxyz0123456789"
	audioFiles [][]byte = make([][]byte, len(dictionary))
)

func loadAudioFile(char byte) []byte {
	path := fmt.Sprintf("assets/%s.wav", string(char))
	data, err := os.ReadFile(path)
	if err != nil {
		log.Fatalf("Failed to load an audio file: %s", err)
	}
	return data
}

func init() {
	audioFiles = make([][]byte, len(dictionary))
	for i := 0; i < len(dictionary); i++ {
		audioFiles[i] = loadAudioFile(dictionary[i])
	}
}
