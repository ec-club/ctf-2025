import os
import logging
from nanoid import generate

logger = logging.getLogger(__name__)


def generate_flag() -> str:
    try:
        flag_template = os.getenv("FLAG")
        flag = (
            flag_template.replace("$1", generate(size=8))
            .replace("$2", generate(size=8))
            .replace("$3", generate(size=8))
        )
        logger.info(f"Generated flag: {flag}")
        return flag
    except:
        return "Something went terribly wrong, please contact an admin on Discord."
