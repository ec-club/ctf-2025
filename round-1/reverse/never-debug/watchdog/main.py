import os
import logging
import secrets

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def generate_flag():
    template = os.getenv("FLAG")
    if not template:
        return "If you see this, please create a ticket in Discord."
    flag = template.replace("(1)", secrets.token_urlsafe(8)).replace(
        "(2)", secrets.token_urlsafe(8)
    )
    logger.info(f"Generated flag: {flag}")
    return flag


import psycopg2


def push_flag(flag):
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("DB_NAME", "db")
    db_user = os.getenv("DB_USER", "user")
    db_password = os.getenv("DB_PASSWORD", "password")
    conn = psycopg2.connect(
        host=db_host, port=db_port, dbname=db_name, user=db_user, password=db_password
    )
    with conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM flags")
            cur.execute("INSERT INTO flags (flag_text) VALUES (%s)", (flag,))
            conn.commit()
    conn.close()


if __name__ == "__main__":
    import time

    while True:
        flag = generate_flag()
        try:
            push_flag(flag)
            logger.debug("Pushed a new flag successfully")
        except Exception as e:
            logger.error("Failed to push a flag: %s", e)
        time.sleep(30)
