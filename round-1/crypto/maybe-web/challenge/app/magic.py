import os
from nanoid import generate

def generate_flag() -> str:
    flag_template = os.getenv('FLAG')
    return flag_template.replace('$1', generate(size=8)).replace('$2', generate(size=8))
