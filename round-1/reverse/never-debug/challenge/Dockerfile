FROM golang:1.25.2-alpine AS builder
LABEL maintainer="Byambadalai Sumiya"

RUN apk add --no-cache git build-base
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
ENV CGO_ENABLED=0
RUN go build -ldflags="-s -w" -o /out/challenge ./challenge.go

FROM alpine:3.18
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /out/challenge /app/challenge
EXPOSE 8080
ENTRYPOINT ["/app/challenge"]
