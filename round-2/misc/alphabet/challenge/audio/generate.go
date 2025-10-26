package audio

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"log"
)

func GenerateAudioFile(data string) []byte {
	type wavFmt struct {
		channels      uint16
		sampleRate    uint32
		bitsPerSample uint16
	}

	parseWAV := func(b []byte) (wavFmt, []byte, error) {
		var f wavFmt
		if len(b) < 12 || string(b[0:4]) != "RIFF" || string(b[8:12]) != "WAVE" {
			return f, nil, fmt.Errorf("invalid WAV header")
		}
		off := 12
		var dataChunk []byte
		for off+8 <= len(b) {
			id := string(b[off : off+4])
			size := binary.LittleEndian.Uint32(b[off+4 : off+8])
			off += 8
			if off+int(size) > len(b) {
				return f, nil, fmt.Errorf("invalid chunk size")
			}
			switch id {
			case "fmt ":
				if size < 16 {
					return f, nil, fmt.Errorf("unsupported fmt chunk")
				}
				audioFormat := binary.LittleEndian.Uint16(b[off : off+2])
				if audioFormat != 1 {
					return f, nil, fmt.Errorf("only PCM supported")
				}
				f.channels = binary.LittleEndian.Uint16(b[off+2 : off+4])
				f.sampleRate = binary.LittleEndian.Uint32(b[off+4 : off+8])
				f.bitsPerSample = binary.LittleEndian.Uint16(b[off+14 : off+16])
			case "data":
				dataChunk = b[off : off+int(size)]
			}
			// Chunks are padded to even sizes
			pad := int(size)
			if pad%2 == 1 {
				pad++
			}
			off += pad
		}
		if dataChunk == nil {
			return f, nil, fmt.Errorf("no data chunk found")
		}
		return f, dataChunk, nil
	}

	var targetFmt wavFmt
	var combinedData [][]byte
	var totalDataLen int

	for _, ch := range data {
		fm, dataChunk, err := parseWAV(audioFiles[bytes.IndexByte([]byte(dictionary), byte(ch))])
		if err != nil {
			log.Printf("failed to parse a wav file: %v", err)
			continue
		}
		if totalDataLen == 0 {
			targetFmt = fm
		}
		combinedData = append(combinedData, dataChunk)
		totalDataLen += len(dataChunk)
	}

	// If nothing collected, return empty
	if totalDataLen == 0 {
		return nil
	}

	// Build a canonical 44-byte PCM WAV header
	hdr := make([]byte, 44)
	copy(hdr[0:4], "RIFF")
	binary.LittleEndian.PutUint32(hdr[4:8], uint32(36+totalDataLen))
	copy(hdr[8:12], "WAVE")
	copy(hdr[12:16], "fmt ")
	binary.LittleEndian.PutUint32(hdr[16:20], 16)                   // PCM fmt chunk size
	binary.LittleEndian.PutUint16(hdr[20:22], 1)                    // PCM format
	binary.LittleEndian.PutUint16(hdr[22:24], targetFmt.channels)   // channels
	binary.LittleEndian.PutUint32(hdr[24:28], targetFmt.sampleRate) // sample rate
	byteRate := targetFmt.sampleRate * uint32(targetFmt.channels) * uint32(targetFmt.bitsPerSample) / 8
	binary.LittleEndian.PutUint32(hdr[28:32], byteRate) // byte rate
	blockAlign := uint16(targetFmt.channels) * targetFmt.bitsPerSample / 8
	binary.LittleEndian.PutUint16(hdr[32:34], blockAlign)              // block align
	binary.LittleEndian.PutUint16(hdr[34:36], targetFmt.bitsPerSample) // bits per sample
	copy(hdr[36:40], "data")
	binary.LittleEndian.PutUint32(hdr[40:44], uint32(totalDataLen)) // data size

	buf := bytes.NewBuffer(make([]byte, 0, 44+totalDataLen))
	buf.Write(hdr)
	for _, d := range combinedData {
		buf.Write(d)
	}

	return buf.Bytes()
}
