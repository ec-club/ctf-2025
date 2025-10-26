FROM ghcr.io/astral-sh/uv@sha256:19a8c92b461bbc32e8bd30c15132cec1d16c49c61f4359c9225262938485f513

WORKDIR /app

RUN uv venv
ENV PATH="/app/.venv/bin:$PATH"

COPY requirements.txt .
RUN uv pip install -r requirements.txt

COPY app .

RUN useradd -m app && chown -R app:app /app

EXPOSE 8000

USER app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

CMD ["fastapi", "run", "main.py", "--forwarded-allow-ips='*'"]
