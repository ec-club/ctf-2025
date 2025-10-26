# step1_create_firmware.py

import os
import json
import tarfile
import shutil


def create_firmware():
    print("[*] Creating LISA AVN Firmware...")

    # 디렉토리 생성
    if os.path.exists("firmware_root"):
        shutil.rmtree("firmware_root")

    os.makedirs("firmware_root/bootloader", exist_ok=True)
    os.makedirs("firmware_root/system", exist_ok=True)
    os.makedirs("firmware_root/config", exist_ok=True)

    # 1. Bootloader (dummy ELF)
    with open("firmware_root/bootloader/boot.bin", "wb") as f:
        f.write(b"\x7fELF\x02\x01\x01\x00" + os.urandom(2048))

    # 2. AVN Main (dummy ELF)
    with open("firmware_root/system/avn_main", "wb") as f:
        # ELF header + random data
        f.write(b"\x7fELF\x02\x01\x01\x00" + os.urandom(16384))

    # 3. Navigation DB (dummy)
    with open("firmware_root/system/navigation.db", "wb") as f:
        f.write(b"SQLite format 3\x00" + os.urandom(8192))

    # 4. Vehicle Config
    vehicle_conf = """# LISA Motors Quantum X Configuration
[VEHICLE]
Manufacturer=LISA Motors
Model=Quantum X
Year=2025
VIN=LIS4M0T0R5EV2025X

[AVN]
Version=3.14.159
Display=1920x1080
Protocol=LAP_v2.0
"""
    with open("firmware_root/config/vehicle.conf", "w") as f:
        f.write(vehicle_conf)

    # 5. Secrets JSON (FLAG here!)
    secrets = {
        "vehicle_info": {
            "manufacturer": "LISA Motors",
            "model": "Quantum X",
            "vin": "LIS4M0T0R5EV2025X",
            "year": 2025,
            "production_date": "2025-03-15",
        },
        "avn_config": {
            "software_version": "AVN_v3.14.159",
            "map_version": "2025.10",
            "screen_resolution": "1920x1080",
            "bluetooth_mac": "4C:49:53:41:32:30",
            "wifi_supported": True,
        },
        "security": {
            "encryption": "AES-128-ECB",
            "protocol": "LISA Automotive Protocol v2.0",
            "auth_token": "ECTF{L1S4_F0T4_AVN_M4ST3R_2025}",
            "last_update": "2025-10-14T15:30:00Z",
            "update_server": "fota.lisamotors.com",
        },
        "diagnostics": {
            "obd2_supported": True,
            "can_bus_speed": "500kbps",
            "ecu_list": ["Engine", "Battery", "AVN", "ADAS"],
        },
    }

    with open("firmware_root/config/secrets.json", "w") as f:
        json.dump(secrets, f, indent=2)

    # README 추가
    readme = """LISA Motors AVN Firmware v3.14.159

This firmware package contains:
- Bootloader
- AVN Main Application
- Navigation Database
- Configuration Files

For internal use only.
(c) 2025 LISA Motors Corporation
"""
    with open("firmware_root/README.txt", "w") as f:
        f.write(readme)

    # tar.gz로 압축
    print("[*] Creating tar.gz archive...")
    with tarfile.open("firmware.tar.gz", "w:gz") as tar:
        tar.add("firmware_root", arcname="lisa_avn_firmware")

    # 펌웨어 데이터 읽기
    firmware_data = open("firmware.tar.gz", "rb").read()

    # AES padding (PKCS7)
    pad_len = 16 - (len(firmware_data) % 16)
    firmware_data += bytes([pad_len] * pad_len)

    # 저장
    with open("firmware_padded.bin", "wb") as f:
        f.write(firmware_data)

    print(f"[+] Firmware created: {len(firmware_data)} bytes")
    print(f"[+] Original size: {len(open('firmware.tar.gz','rb').read())} bytes")
    print(f"[+] Padded size: {len(firmware_data)} bytes")
    print(f"[+] FLAG: LISA{{L1S4_F0T4_AVN_M4ST3R_2025}}")

    return firmware_data


if __name__ == "__main__":
    create_firmware()
