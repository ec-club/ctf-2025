FROM --platform=linux/amd64 ubuntu:24.04 AS builder

WORKDIR /app

RUN apt-get update && apt-get install gcc libseccomp-dev -y && rm -rf /var/lib/apt/lists/*
COPY . .

RUN gcc -o challenge challenge.c -lseccomp

FROM --platform=linux/amd64 ubuntu:24.04

RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder --chmod=555 /app/challenge /app/challenge

EXPOSE 1337
CMD ["socat", "TCP-LISTEN:1337,reuseaddr,fork", "EXEC:/app/challenge"]
