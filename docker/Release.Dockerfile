FROM golang:1.22.1 as builder

WORKDIR /app

COPY main.go go.mod go.sum /app/
COPY webroot/ /app/webroot/
COPY src/sql/ /app/src/sql/
COPY src/go/ /app/src/go/
COPY generated/go/ /app/generated/go/

RUN apt-get update && apt-get install -y gcc libc6-dev

ENV CGO_ENABLED=1
RUN go build -tags 'netgo sqlite_stat4 sqlite_fts5 sqlite_math_functions sqlite_vtable' -ldflags '-extldflags "-static"' -o res-mon



FROM debian:bullseye-slim

RUN mkdir /app && groupadd -r appuser && useradd -r -g appuser -d /app appuser && chown appuser:appuser /app && chmod 500 /app

WORKDIR /app
EXPOSE 8321

CMD ["./res-mon"]
ENTRYPOINT ["/app/entrypoint.sh"]
HEALTHCHECK --interval=1m --timeout=15s --start-period=30s --retries=5 CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8321/ || exit 1

COPY docker/entrypoint.sh /app/entrypoint.sh
RUN chown root:root entrypoint.sh && chmod 500 entrypoint.sh && apt-get update && apt-get install -y ca-certificates wget gosu && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/res-mon .