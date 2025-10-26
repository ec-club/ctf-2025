# solve_fixed.py

from scapy.all import *
from Crypto.Cipher import AES
import struct
import zlib

def crc32(data):
    return zlib.crc32(data) & 0xFFFFFFFF

def parse_packet(data):
    """Parse LAP protocol packet"""
    try:
        sof = struct.unpack('>H', data[0:2])[0]
        if sof != 0x4C15:
            return None

        ecu = struct.unpack('>H', data[2:4])[0]
        service = data[4]
        seq = struct.unpack('>H', data[5:7])[0]
        total = struct.unpack('>H', data[7:9])[0]
        length = struct.unpack('>H', data[9:11])[0]

        payload = data[11:11+length]
        crc_recv = struct.unpack('>I', data[11+length:15+length])[0]
        eof = struct.unpack('>H', data[15+length:17+length])[0]

        # Verify CRC
        crc_calc = crc32(data[:11+length])

        return {
            'service': service,
            'seq': seq,
            'total': total,
            'payload': payload,
            'crc_valid': (crc_calc == crc_recv),
            'eof_valid': (eof == 0x454E)
        }
    except:
        return None

def solve():
    print("[*] Loading PCAP...")
    packets = rdpcap('lisa_fota_capture.pcap')
    print(f"[*] Total packets: {len(packets)}")

    aes_key = None
    fw_chunks = {}
    total_chunks = 0

    print("[*] Parsing packets...")
    for pkt in packets:
        if Raw not in pkt:
            continue

        data = bytes(pkt[Raw])
        parsed = parse_packet(data)

        if not parsed:
            continue

        # Find AES Key (Service 0x27, subfunction 0x03)
        if parsed['service'] == 0x27:
            if len(parsed['payload']) >= 17 and parsed['payload'][0] == 0x03:
                aes_key = parsed['payload'][1:17]
                print(f"[+] Found AES Key: {aes_key.hex()}")

        # Collect firmware chunks (Service 0x36)
        if parsed['service'] == 0x36:
            seq = parsed['seq']
            total_chunks = max(total_chunks, parsed['total'])

            # CRC가 유효하거나 EOF가 유효하면 청크 수집
            # (손상된 패킷도 포함, 나중에 복구 시도)
            if parsed['eof_valid']:
                fw_chunks[seq] = parsed['payload']

                # Debug: 청크 크기 확인
                if seq < 5:
                    crc_status = "OK" if parsed['crc_valid'] else "BAD"
                    print(f"[DEBUG] Chunk {seq}: {len(parsed['payload'])} bytes [CRC: {crc_status}]")

    if not aes_key:
        print("[-] AES Key not found!")
        return

    print(f"[*] Collected {len(fw_chunks)} valid chunks (expected: {total_chunks})")
    print(f"[*] Missing chunks: {total_chunks - len(fw_chunks)}")

    # 누락된 청크 확인
    missing = []
    for i in range(total_chunks):
        if i not in fw_chunks:
            missing.append(i)

    if missing:
        print(f"[!] Missing chunk indices: {missing[:10]}..." if len(missing) > 10 else f"[!] Missing chunk indices: {missing}")

    # Sort and combine
    print("[*] Sorting chunks...")
    encrypted_fw = b''.join([fw_chunks[i] for i in sorted(fw_chunks.keys())])
    print(f"[*] Encrypted firmware size: {len(encrypted_fw)} bytes")

    # Decrypt
    print("[*] Decrypting...")
    cipher = AES.new(aes_key, AES.MODE_ECB)
    decrypted = cipher.decrypt(encrypted_fw)

    # Remove PKCS7 padding
    pad_len = decrypted[-1]
    print(f"[DEBUG] Detected padding length: {pad_len}")

    # 패딩이 유효한지 확인
    if pad_len > 16 or pad_len < 1:
        print(f"[!] Warning: Invalid padding length {pad_len}, trying without padding removal")
        firmware = decrypted
    else:
        # 패딩 바이트가 모두 같은지 확인
        if all(b == pad_len for b in decrypted[-pad_len:]):
            firmware = decrypted[:-pad_len]
            print(f"[*] Valid PKCS7 padding removed")
        else:
            print(f"[!] Warning: Invalid padding bytes, trying without padding removal")
            firmware = decrypted

    print(f"[*] Decrypted firmware size: {len(firmware)} bytes")

    # 원본 파일 크기와 비교
    try:
        original_size = os.path.getsize('firmware.tar.gz')
        print(f"[*] Original firmware.tar.gz size: {original_size} bytes")
        print(f"[*] Size difference: {original_size - len(firmware)} bytes")
    except:
        pass

    # Save
    with open('firmware_extracted.tar.gz', 'wb') as f:
        f.write(firmware)

    print("[+] Firmware saved: firmware_extracted.tar.gz")

    # 파일 헤더 확인
    print(f"[DEBUG] First 16 bytes: {firmware[:16].hex()}")

    # Try to extract
    import tarfile
    try:
        print("[*] Attempting to extract...")
        with tarfile.open('firmware_extracted.tar.gz', 'r:gz') as tar:
            tar.extractall('.')

        print("[+] Extraction successful!")

        # Find flag
        import json
        with open('lisa_avn_firmware/config/secrets.json', 'r') as f:
            secrets = json.load(f)
            flag = secrets['security']['auth_token']
            print(f"\n[+] FLAG: {flag}")
    except Exception as e:
        print(f"[-] Error extracting: {e}")
        print("\n[*] Trying alternative extraction methods...")

        # gunzip만 시도
        import gzip
        try:
            with gzip.open('firmware_extracted.tar.gz', 'rb') as gz:
                tar_data = gz.read()
            print(f"[+] Gunzip successful! Tar size: {len(tar_data)} bytes")

            # tar 파일로 저장
            with open('firmware_extracted.tar', 'wb') as f:
                f.write(tar_data)

            # tar 추출
            with tarfile.open('firmware_extracted.tar', 'r') as tar:
                tar.extractall('.')

            print("[+] Extraction successful via gunzip!")

            # Find flag
            import json
            with open('lisa_avn_firmware/config/secrets.json', 'r') as f:
                secrets = json.load(f)
                flag = secrets['security']['auth_token']
                print(f"\n[+] FLAG: {flag}")
        except Exception as e2:
            print(f"[-] Alternative method also failed: {e2}")

if __name__ == '__main__':
    solve()
