FROM golang:latest as builder

WORKDIR /app

COPY main.go go.mod go.sum /app/
COPY webroot/ /app/webroot/
COPY src/sql/ /app/src/sql/
COPY src/go/ /app/src/go/
COPY generated/go/ /app/generated/go/

RUN apt-get update && apt-get install -y gcc libc6-dev

ENV CGO_ENABLED=1
RUN go build -tags 'netgo sqlite_stat4 sqlite_fts5 sqlite_math_functions' -ldflags '-extldflags "-static"' -o res-mon



FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y ca-certificates wget && rm -rf /var/lib/apt/lists/*
RUN mkdir /app && groupadd -r appuser && useradd -r -g appuser -d /app appuser


RUN chown appuser:appuser /app && chmod 500 /app
RUN mkdir /app/data && chown appuser:appuser /app/data && chmod 500 /app/data

RUN touch /app/data/database.db && chown appuser:appuser /app/data/database.db && chmod 600 /app/data/database.db
RUN touch /app/data/database.db-shm && chown appuser:appuser /app/data/database.db-shm && chmod 600 /app/data/database.db-shm
RUN touch /app/data/database.db-wal && chown appuser:appuser /app/data/database.db-wal && chmod 600 /app/data/database.db-wal

WORKDIR /app
COPY --from=builder /app/res-mon .
RUN chown appuser:appuser res-mon && chmod 500 res-mon

EXPOSE 8321
USER appuser

CMD ["./res-mon"]
HEALTHCHECK --interval=1m --timeout=15s --start-period=30s --retries=5 CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8321/ || exit 1
