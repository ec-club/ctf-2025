import os
import base64
import secrets
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

with open('wordlist.txt', 'r', encoding='latin-1') as dictionary:
    passwords = list(map(lambda password: password.strip(), dictionary.readlines()))
    password = secrets.choice(passwords)

def _derive_key(passphrase: str, salt: bytes) -> bytes:
  kdf = PBKDF2HMAC(
    algorithm=hashes.SHA256(),
    length=32,
    salt=salt,
    iterations=200_000,
  )
  return kdf.derive(passphrase.encode("utf-8"))

def aes256_gcm_encrypt(plaintext: bytes, aad: bytes = b"") -> bytes:
  salt = os.urandom(16)
  nonce = os.urandom(12)
  key = _derive_key(password, salt)
  ct = AESGCM(key).encrypt(nonce, plaintext, aad)
  return salt + nonce + ct  # blob = 16-byte salt || 12-byte nonce || ciphertext || tag

def aes256_gcm_decrypt(blob: bytes, aad: bytes = b"") -> bytes:
  salt, nonce, ct = blob[:16], blob[16:28], blob[28:]
  key = _derive_key(password, salt)
  return AESGCM(key).decrypt(nonce, ct, aad)

if __name__ == "__main__":
  flag = f"REDACTED".encode()
  aad = b"What is AAD?"
  blob = aes256_gcm_encrypt(flag, aad)
  print(base64.b64encode(blob).decode())
  print(aad)
  assert aes256_gcm_decrypt(blob, aad) == flag
  assert password in passwords
