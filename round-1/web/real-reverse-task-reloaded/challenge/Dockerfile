FROM rust:1.90.0-bookworm AS builder

WORKDIR /app

COPY . .
RUN cargo build --release

# See: https://labs.iximiuz.com/tutorials/gcr-distroless-container-images
FROM gcr.io/distroless/cc-debian12:nonroot

COPY --from=builder /app/target/release/reverse-task /app

EXPOSE 8080
ENTRYPOINT ["/app"]
