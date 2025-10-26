# LISA Automotive Protocol (LAP) Specification v2.0

## Packet Structure

| Offset | Size | Field    | Description                   |
| ------ | ---- | -------- | ----------------------------- |
| 0x00   | 2    | SOF      | Start of Frame (0x4C15)       |
| 0x02   | 2    | ECU_ID   | ECU Identifier (0x4156 = AVN) |
| 0x04   | 1    | Service  | Service ID                    |
| 0x05   | 2    | Sequence | Packet sequence number        |
| 0x07   | 2    | Total    | Total packet count            |
| 0x09   | 2    | Length   | Payload length                |
| 0x0B   | N    | Payload  | Data                          |
| N+11   | 4    | CRC32    | Checksum                      |
| N+15   | 2    | EOF      | End of Frame (0x454E)         |

## Service IDs

- 0x10: Diagnostic Session Control
- 0x22: Read Data By Identifier
- 0x27: Security Access
- 0x34: Request Download
- 0x36: Transfer Data
- 0x37: Request Transfer Exit
- 0x3E: Tester Present (Heartbeat)

## Security Access (0x27)

Subfunction 0x03: Key Exchange

- Request: 27 03
- Response: 67 03 [16-byte AES key] [CRC]

## Data Transfer (0x36)

Used for firmware upload.

- Payload contains encrypted firmware chunks
- Use Sequence field to reassemble
- Verify CRC32 before processing
