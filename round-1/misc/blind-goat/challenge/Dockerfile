FROM golang:1.25 AS build

WORKDIR /go/src/app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o /go/bin/app cmd/main.go

FROM busybox:1.37

RUN rm $(which grep)

COPY --from=build /go/bin/app /

USER 1000:1000
CMD ["/app"]
