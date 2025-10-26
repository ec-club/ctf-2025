import json
import base64

from meta import client, key_id


def generate_token(username: str) -> str:
    header = {"alg": "ML-DSA-65", "typ": "JWT"}
    body = {"username": username, "is_admin": False}
    unsigned_token = (
        ".".join(
            map(
                lambda data: base64.urlsafe_b64encode(json.dumps(data).encode())
                .decode()
                .rstrip("="),
                [header, body],
            )
        )
        + "."
    )
    result = client.sign(
        KeyId=key_id,
        Message=unsigned_token.encode(),
        MessageType="RAW",
        SigningAlgorithm="ML_DSA_SHAKE_256",
    )["Signature"]
    return unsigned_token + base64.urlsafe_b64encode(result).decode().rstrip("=")


def verify_token(token: str) -> bool:
    parts = token.split(".")
    if len(parts) != 3:
        return False
    try:
        unsigned_token = ".".join(parts[0:2]) + "."
        signature = base64.urlsafe_b64decode(parts[2] + "==")
    except Exception:
        return False
    result = client.verify(
        KeyId=key_id,
        Message=unsigned_token.encode(),
        Signature=signature,
        SigningAlgorithm="ML_DSA_SHAKE_256",
    )
    if not result["SignatureValid"]:
        return False

    try:
        header = json.loads(base64.urlsafe_b64decode(parts[0] + "==").decode())
        if header["alg"] != "ML-DSA-65" or header["typ"] != "JWT":
            return False
    except:
        return False
    try:
        claims = json.loads(base64.urlsafe_b64decode(parts[1] + "==").decode())
    except:
        return False
    return claims["is_admin"]
