FROM ubuntu@sha256:d22e4fb389065efa4a61bb36416768698ef6d955fe8a7e0cdb3cd6de80fa7eec AS binary-builder

WORKDIR /app

RUN apt-get update && apt-get install gcc libseccomp-dev -y && rm -rf /var/lib/apt/lists/*
COPY binary/challenge.c .

RUN gcc -o challenge challenge.c -lseccomp

FROM golang@sha256:4a839c047a4acc07d4a8c2c36d9816785a0ffa607cab75ab59639584fffed0e6 AS server-builder

WORKDIR /go/src/app
COPY go.mod go.sum ./
RUN go mod download

RUN apt-get update && apt-get install git cmake build-essential -y && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch 4.0.2 https://github.com/capstone-engine/capstone && cd capstone && mkdir build && cd build && cmake .. && cmake --build . --config Release --target install

COPY . .
RUN go build -o /go/bin/server cmd/main.go

FROM debian@sha256:66b37a5078a77098bfc80175fb5eb881a3196809242fd295b25502854e12cbec

WORKDIR /app

COPY --from=server-builder /usr/local/lib/libcapstone.so.4 /usr/local/lib/libcapstone.so.4
RUN ldconfig

COPY --from=server-builder --chmod=111 /go/bin/server /app/server
COPY --from=binary-builder --chmod=111 /app/challenge /app/challenge

USER 1000:1000
CMD ["/app/server"]
