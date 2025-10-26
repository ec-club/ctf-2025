import os
import json
import base64
from typing import Optional, Tuple
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

key = os.urandom(64)
iv = os.urandom(16)


def verify_token(token: str) -> Tuple[bool, Optional[bytes]]:
    try:
        protected_header_b64, _, iv_b64, ciphertext_b64, _ = token.split(".")
        protected_header = json.loads(
            base64.urlsafe_b64decode(protected_header_b64 + "==")
        )
        iv = base64.urlsafe_b64decode(iv_b64 + "==")
        ciphertext = base64.urlsafe_b64decode(ciphertext_b64 + "==")
        if (
            protected_header.get("alg") != "dir"
            or protected_header.get("enc") != "A256XTS"
        ):
            return False, None
        decrypted = (
            Cipher(algorithms.AES(key), modes.XTS(iv)).decryptor().update(ciphertext)
        )
        try:
            data = json.loads(decrypted)
        except:
            return False, decrypted
        return data.get("is_admin"), None
    except Exception as e:
        return False, None


def build_token_contents(username: str, password: str) -> str:
    return json.dumps(
        {"username": username, "password": password, "is_admin": False},
        ensure_ascii=False,
    )


def generate_token(username: str, password: str) -> str:
    protected_header = json.dumps({"alg": "dir", "enc": "A256XTS"}).encode()
    contents = build_token_contents(username, password).encode("latin-1")
    ciphertext = Cipher(algorithms.AES(key), modes.XTS(iv)).encryptor().update(contents)
    encrypted_key = b""
    tag = b""
    token = map(
        lambda data: base64.urlsafe_b64encode(data).decode().rstrip("="),
        [protected_header, encrypted_key, iv, ciphertext, tag],
    )
    return ".".join(token)
