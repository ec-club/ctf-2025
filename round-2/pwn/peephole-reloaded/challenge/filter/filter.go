package filter

import (
	"log"

	"github.com/knightsc/gapstone"
)

func verifyShellcode(peerAddress string, channelID int64, shellcode []byte) (bool, error) {
	engine, err := gapstone.New(
		gapstone.CS_ARCH_X86,
		gapstone.CS_MODE_64,
	)
	if err != nil {
		return false, err
	}
	defer engine.Close()

	insns, err := engine.Disasm(
		[]byte(shellcode),
		0x10000,
		0,
	)
	if err != nil {
		log.Printf("Disassembly error: %v", err)
		return false, nil
	}
	log.Printf("[%s|%d] Incoming shellcode:\n", peerAddress, channelID)
	for _, insn := range insns {
		log.Printf("[%s|%d] 0x%x:\t%s\t\t%s\n", peerAddress, channelID, insn.Address, insn.Mnemonic, insn.OpStr)
	}

	return true, nil
}
