FROM ghcr.io/astral-sh/uv:0.9.2-python3.14-alpine
LABEL maintainer="Zolboobayar Gantumur <zolboobayar.g@empasoft.ider.edu.mn>"

WORKDIR /app

RUN uv venv
ENV PATH="/app/.venv/bin:$PATH"

RUN uv pip install psycopg2-binary

COPY --chmod=444 main.py ./
USER 1337:1337

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
CMD ["python3", "main.py"]
