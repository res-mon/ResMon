FROM golang:latest as builder

WORKDIR /app

COPY main.go go.mod go.sum /app/
COPY webroot/ /app/webroot/
COPY src/go/ /app/src/go/

RUN apt-get update && apt-get install -y gcc libc6-dev

ENV CGO_ENABLED=1
RUN go build -tags netgo -ldflags '-extldflags "-static"' -o res-mon

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y ca-certificates wget && rm -rf /var/lib/apt/lists/*
RUN groupadd -r appuser && useradd -r -g appuser -d /app appuser

WORKDIR /app
COPY --from=builder /app/res-mon .
RUN chown appuser:appuser res-mon && chmod 500 res-mon
RUN mkdir /app/data && chown appuser:appuser /app/data && chmod 500 /app/data
RUN touch /app/data/database.db chown appuser:appuser /app/data/database.db && chmod 500 /app/data/database.db

EXPOSE 8321
USER appuser

CMD ["./res-mon"]
HEALTHCHECK --interval=1m --timeout=15s --start-period=30s --retries=5 CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8123/ || exit 1

