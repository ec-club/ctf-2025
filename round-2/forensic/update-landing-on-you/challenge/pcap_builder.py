# step2_generate_pcap.py

from scapy.all import *
from Crypto.Cipher import AES
import struct
import random
import zlib

# === Configuration ===
SERVER_IP = "192.168.100.10"
CLIENT_IP = "192.168.100.50"
SERVER_PORT = 13400
CLIENT_PORT = random.randint(50000, 60000)

AES_KEY = bytes.fromhex("4C4953416D6F746F7273323032354156")  # "LISAmotors2025AV"
CHUNK_SIZE = 256
CORRUPTION_RATE = 0.05  # 5% 손상

# === Protocol Constants ===
SOF = 0x4C15  # "LISA" compressed
EOF = 0x454E  # "EN"
ECU_AVN = 0x4156  # "AV"

# Service IDs
SVC_DIAG = 0x10
SVC_SECURITY = 0x27
SVC_REQUEST_DL = 0x34
SVC_TRANSFER = 0x36
SVC_TRANSFER_EXIT = 0x37
SVC_HEARTBEAT = 0x3E
SVC_READ_DATA = 0x22

def crc32(data):
    """Calculate CRC32"""
    return zlib.crc32(data) & 0xFFFFFFFF

def create_packet(service, data, seq=0, total=0):
    """Create LAP protocol packet"""
    packet = struct.pack('>H', SOF)  # Start of Frame
    packet += struct.pack('>H', ECU_AVN)  # ECU ID
    packet += struct.pack('B', service)  # Service ID
    packet += struct.pack('>H', seq)  # Sequence
    packet += struct.pack('>H', total)  # Total packets
    packet += struct.pack('>H', len(data))  # Length
    packet += data
    
    # CRC32 of everything before EOF
    crc = crc32(packet)
    packet += struct.pack('>I', crc)
    packet += struct.pack('>H', EOF)  # End of Frame
    
    return packet

def create_corrupted_packet(service, data, seq=0, total=0):
    """Create packet with wrong CRC"""
    packet = struct.pack('>H', SOF)
    packet += struct.pack('>H', ECU_AVN)
    packet += struct.pack('B', service)
    packet += struct.pack('>H', seq)
    packet += struct.pack('>H', total)
    packet += struct.pack('>H', len(data))
    packet += data
    
    # Wrong CRC
    fake_crc = random.randint(0, 0xFFFFFFFF)
    packet += struct.pack('>I', fake_crc)
    packet += struct.pack('>H', EOF)
    
    return packet

def send_packet(pkt_list, payload, timestamp):
    """Add packet to list with timestamp"""
    pkt = IP(src=CLIENT_IP, dst=SERVER_IP) / \
          UDP(sport=CLIENT_PORT, dport=SERVER_PORT) / \
          Raw(load=payload)
    pkt.time = timestamp
    pkt_list.append(pkt)

def generate_pcap():
    print("[*] Generating PCAP file...")
    
    # Load firmware
    firmware = open('firmware_padded.bin', 'rb').read()
    print(f"[*] Firmware size: {len(firmware)} bytes")
    
    # Encrypt firmware
    print("[*] Encrypting firmware with AES...")
    cipher = AES.new(AES_KEY, AES.MODE_ECB)
    encrypted_fw = cipher.encrypt(firmware)
    
    # Split into chunks
    chunks = []
    for i in range(0, len(encrypted_fw), CHUNK_SIZE):
        chunks.append(encrypted_fw[i:i+CHUNK_SIZE])
    
    total_chunks = len(chunks)
    print(f"[*] Split into {total_chunks} chunks")
    
    packets = []
    timestamp = 1728900000.0  # 2025-10-14 base timestamp
    
    # === Phase 1: Handshake ===
    print("[*] Phase 1: Handshake")
    
    # Diagnostic Session Request
    payload = create_packet(SVC_DIAG, b'\x03\x01')  # Programming session
    send_packet(packets, payload, timestamp)
    timestamp += 0.012
    
    # Positive Response
    payload = create_packet(SVC_DIAG + 0x40, b'\x03\x01\x00\x32\x00\xC8')
    send_packet(packets, payload, timestamp)
    timestamp += 0.015
    
    # VIN Request
    payload = create_packet(SVC_READ_DATA, b'\xF1\x90')  # Read VIN
    send_packet(packets, payload, timestamp)
    timestamp += 0.010
    
    # VIN Response
    vin_data = b'LIS4M0T0R5EV2025X'
    payload = create_packet(SVC_READ_DATA + 0x40, b'\xF1\x90' + vin_data)
    send_packet(packets, payload, timestamp)
    timestamp += 0.020
    
    # Heartbeat
    payload = create_packet(SVC_HEARTBEAT, b'\x00')
    send_packet(packets, payload, timestamp)
    timestamp += 0.050
    
    # === Phase 2: Key Exchange (150번째쯤) ===
    # Noise 패킷 먼저 추가
    print("[*] Adding initial noise packets...")
    for _ in range(15):
        if random.random() < 0.5:
            payload = create_packet(SVC_HEARTBEAT, b'\x00')
        else:
            payload = create_packet(SVC_READ_DATA, bytes([random.randint(0, 255)] * 4))
        send_packet(packets, payload, timestamp)
        timestamp += random.uniform(0.01, 0.05)
    
    # Security Access - Key Exchange
    print("[*] Phase 2: Key Exchange")
    payload = create_packet(SVC_SECURITY, b'\x03' + AES_KEY)  # Service 0x27, subfunction 0x03
    send_packet(packets, payload, timestamp)
    timestamp += 0.025
    
    # Positive Response
    payload = create_packet(SVC_SECURITY + 0x40, b'\x03')
    send_packet(packets, payload, timestamp)
    timestamp += 0.030
    
    # More noise
    for _ in range(10):
        payload = create_packet(SVC_HEARTBEAT, b'\x00')
        send_packet(packets, payload, timestamp)
        timestamp += random.uniform(0.01, 0.03)
    
    # === Phase 3: Request Download ===
    print("[*] Phase 3: Request Download")
    dl_info = struct.pack('>I', len(encrypted_fw)) + b'\x01'  # Size + encryption flag
    payload = create_packet(SVC_REQUEST_DL, dl_info)
    send_packet(packets, payload, timestamp)
    timestamp += 0.020
    
    # Positive Response
    payload = create_packet(SVC_REQUEST_DL + 0x40, struct.pack('>H', CHUNK_SIZE))
    send_packet(packets, payload, timestamp)
    timestamp += 0.040
    
    # === Phase 4: Transfer Data ===
    print(f"[*] Phase 4: Transferring {total_chunks} chunks...")
    
    # 순서 섞기
    indices = list(range(total_chunks))
    random.shuffle(indices)
    
    # Determine which packets to corrupt
    corrupt_indices = set(random.sample(indices, int(total_chunks * CORRUPTION_RATE)))
    
    transfer_packets = []
    for idx in indices:
        chunk = chunks[idx]
        
        if idx in corrupt_indices:
            # 손상된 패킷
            payload = create_corrupted_packet(SVC_TRANSFER, chunk, idx, total_chunks)
        else:
            # 정상 패킷
            payload = create_packet(SVC_TRANSFER, chunk, idx, total_chunks)
        
        transfer_packets.append((payload, timestamp))
        timestamp += random.uniform(0.005, 0.015)
        
        # Noise 패킷 간간이 추가
        if random.random() < 0.1:  # 10% 확률
            noise_payload = create_packet(SVC_HEARTBEAT, b'\x00')
            transfer_packets.append((noise_payload, timestamp))
            timestamp += random.uniform(0.005, 0.01)
    
    # Add all transfer packets
    for payload, ts in transfer_packets:
        send_packet(packets, payload, ts)
    
    print(f"[*] Total transfer packets: {len(transfer_packets)}")
    print(f"[*] Corrupted packets: {len(corrupt_indices)}")
    
    # === Phase 5: Transfer Exit ===
    print("[*] Phase 5: Transfer Exit")
    
    # Calculate checksum of entire encrypted firmware
    fw_checksum = crc32(encrypted_fw)
    payload = create_packet(SVC_TRANSFER_EXIT, struct.pack('>I', fw_checksum))
    send_packet(packets, payload, timestamp)
    timestamp += 0.030
    
    # Positive Response
    payload = create_packet(SVC_TRANSFER_EXIT + 0x40, b'\x00')
    send_packet(packets, payload, timestamp)
    timestamp += 0.020
    
    # Final heartbeats
    for _ in range(5):
        payload = create_packet(SVC_HEARTBEAT, b'\x00')
        send_packet(packets, payload, timestamp)
        timestamp += random.uniform(0.05, 0.1)
    
    # === Save PCAP ===
    print(f"[*] Total packets: {len(packets)}")
    wrpcap('lisa_fota_capture.pcap', packets)
    print("[+] PCAP saved: lisa_fota_capture.pcap")
    
    # Statistics
    print("\n=== Statistics ===")
    print(f"Total packets: {len(packets)}")
    print(f"Firmware chunks: {total_chunks}")
    print(f"Corrupted chunks: {len(corrupt_indices)}")
    print(f"Noise packets: ~{len([p for p in packets if len(bytes(p[Raw])) < 50])}")
    print(f"PCAP size: {os.path.getsize('lisa_fota_capture.pcap') / 1024 / 1024:.2f} MB")

if __name__ == '__main__':
    generate_pcap()
