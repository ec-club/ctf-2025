import hashlib
import base64
from typing import List


def _sha256_int(s: str) -> int:
    return int(hashlib.sha256(s.encode()).hexdigest(), 16)


def _rol8(x: int, r: int) -> int:
    r &= 7
    return ((x << r) & 0xFF) | ((x & 0xFF) >> (8 - r))


def _ror8(x: int, r: int) -> int:
    r &= 7
    return ((_x := (x & 0xFF)) >> r) | ((_x << (8 - r)) & 0xFF)


class _WobbleRNG:
    def __init__(self, seed: int):
        self.s = seed & 0xFFFFFFFF

    def byte(self) -> int:

        self.s = (1103515245 * self.s + 12345) & 0xFFFFFFFF
        return (self.s >> 24) & 0xFF


def _make_sbox(seed_rng: _WobbleRNG) -> List[int]:

    arr = list(range(256))
    for i in range(255, 0, -1):
        j = seed_rng.byte() % (i + 1)
        arr[i], arr[j] = arr[j], arr[i]
    return arr


def _derive_key_bytes(password: str) -> bytes:

    h = hashlib.sha256(password.encode()).digest()

    return (h * 4)[:32]


def encrypt_bytes(plaintext: bytes, password: str) -> bytes:
    key = _derive_key_bytes(password)
    seed = _sha256_int(password) ^ int.from_bytes(key[:4], "big")
    rng = _WobbleRNG(seed)
    sbox = _make_sbox(_WobbleRNG(seed ^ 0xA5A5A5A5))

    out = bytearray()
    klen = len(key)
    for i, pb in enumerate(plaintext):

        t = (pb + rng.byte()) & 0xFF

        kb = key[i % klen]
        t = t ^ kb

        t = _rol8(t, key[(i + 1) % klen])

        t = sbox[t]

        out.append((t + (i & 0xFF)) & 0xFF)

    return base64.b64encode(bytes(out))


def decrypt_bytes(cipher_b64: bytes, password: str) -> bytes:
    data = base64.b64decode(cipher_b64)
    key = _derive_key_bytes(password)
    seed = _sha256_int(password) ^ int.from_bytes(key[:4], "big")
    rng = _WobbleRNG(seed)
    sbox = _make_sbox(_WobbleRNG(seed ^ 0xA5A5A5A5))

    inv = [0] * 256
    for i, v in enumerate(sbox):
        inv[v] = i

    out = bytearray()
    klen = len(key)

    for i in range(len(data)):
        cb = data[i]

        t = (cb - (i & 0xFF)) & 0xFF

        t = inv[t]

        t = _ror8(t, key[(i + 1) % klen])

        kb = key[i % klen]
        t = t ^ kb

        r = rng.byte()
        t = (t - r) & 0xFF

        out.append(t)

    return bytes(out)


def encrypt_text(plaintext: str, password: str) -> str:
    return encrypt_bytes(plaintext.encode(), password).decode()


def decrypt_text(cipher_b64_text: str, password: str) -> str:
    return decrypt_bytes(cipher_b64_text.encode(), password).decode()


if __name__ == "__main__":
    pw = "whatsthat"
    flag = open("flag.txt", "rb").read()
    c = encrypt_bytes(flag, pw)
    print("CIPHERTEXT (base64):", c.decode())

    recovered = decrypt_bytes(c, pw)
    print("Recovered equals original?", recovered == flag)
    if recovered != flag:
        print("Mismatch! Something went wrong.")
    else:
        print("Decrypted preview:", recovered[:80])
