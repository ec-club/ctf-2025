FROM python:3.12-slim AS builder

WORKDIR /app
RUN pip install cryptography --no-cache-dir

COPY . .
RUN python challenge.py > /app/not-flag-yet

FROM scratch
LABEL FLAG=ECTF{https://youtu.be/hvL1339luv0}
COPY --from=builder --chmod=000 /app/not-flag-yet /not-flag-yet
