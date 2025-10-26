import os
import cbor2
import base64
from cryptography.hazmat.primitives import poly1305

key = os.urandom(32)


def generate_token(username: str) -> str:
    token_data = {"sub": username}
    cbor_bytes = cbor2.dumps(token_data)
    mac = poly1305.Poly1305.generate_tag(key, cbor_bytes)
    token = (
        base64.urlsafe_b64encode(cbor_bytes).decode().rstrip("=")
        + "."
        + base64.urlsafe_b64encode(mac).decode().rstrip("=")
    )
    return token


def verify_token(token: str) -> bool:
    try:
        cbor_b64, mac_b64 = token.split(".")
        cbor_bytes = base64.urlsafe_b64decode(cbor_b64 + "==")
        mac = base64.urlsafe_b64decode(mac_b64 + "==")
        expected_mac = poly1305.Poly1305.generate_tag(key, cbor_bytes)
        if mac != expected_mac:
            return False

        data = cbor2.loads(cbor_bytes)
        if "sub" not in data:
            return False
        return "is_admin" in data and data["is_admin"] is True
    except Exception:
        return False
