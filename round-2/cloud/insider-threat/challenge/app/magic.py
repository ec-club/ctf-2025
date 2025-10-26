import os
import sys
import logging
from nanoid import generate

logger = logging.getLogger(__name__)
if not logger.handlers:
    handler = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        "%Y-%m-%d %H:%M:%S",
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    logger.propagate = False


def generate_flag(client_ip: str) -> str:
    try:
        flag_template = os.getenv("FLAG")
        flag = (
            flag_template.replace("$1", generate(size=8))
            .replace("$2", generate(size=8))
            .replace("$3", generate(size=8))
        )
        logger.info(f"Releasing flag {flag} for {client_ip}")
        return flag
    except Exception:
        logger.error("Error generating flag", exc_info=True)
        return "Something went terribly wrong, please contact an admin on Discord."
