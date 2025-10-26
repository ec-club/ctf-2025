package server

import (
	"bytes"
	"encoding/binary"
	"log"

	"golang.org/x/crypto/ssh"
)

type ForwardingChannelRequest struct {
	LocalAddress string
	LocalPort    uint32
	DestAddress  string
	DestPort     uint32
}

func readString(reader *bytes.Reader) (string, error) {
	var strLen uint32
	if err := binary.Read(reader, binary.BigEndian, &strLen); err != nil {
		return "", err
	}
	if strLen == 0 {
		return "", nil
	}

	strBytes := make([]byte, strLen)
	if _, err := reader.Read(strBytes); err != nil {
		return "", err
	}
	return string(strBytes), nil
}

func parseExtraData(data []byte) (*ForwardingChannelRequest, error) {
	reader := bytes.NewReader(data)
	result := &ForwardingChannelRequest{}
	var err error
	result.DestAddress, err = readString(reader)
	if err != nil {
		return nil, err
	}
	if err := binary.Read(reader, binary.BigEndian, &result.DestPort); err != nil {
		return nil, err
	}
	result.LocalAddress, err = readString(reader)
	if err != nil {
		return nil, err
	}
	err = binary.Read(reader, binary.BigEndian, &result.LocalPort)
	if err != nil {
		return nil, err
	}
	return result, nil
}

func handleForwardingChannel(newChannel ssh.NewChannel, pendingPort uint16, connectionChan chan ssh.Channel) {
	forwardReq, err := parseExtraData(newChannel.ExtraData())
	if err != nil {
		log.Printf("Failed to parse forwarding request extra data: %s", err)
		newChannel.Reject(ssh.Prohibited, "Nani?!")
		return
	}
	if uint16(forwardReq.DestPort) != pendingPort {
		newChannel.Reject(ssh.Prohibited, "I won't connect you there!")
		return
	}

	channel, requests, err := newChannel.Accept()
	if err != nil {
		return
	}
	go ssh.DiscardRequests(requests)
	connectionChan <- channel
}
