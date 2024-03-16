FROM golang:1.22.1-alpine3.19 as builder

RUN apk add --no-cache gcc musl-dev sqlite-dev build-base

ENV GOPATH=/go
ENV GOCACHE=/root/.cache/go-build

COPY .go-path/pkg/ /go/pkg/
COPY .go-cache/ /root/.cache/go-build/

WORKDIR /app

COPY main.go go.mod go.sum /app/
COPY webroot/ /app/webroot/
COPY src/sql/ /app/src/sql/
COPY src/go/ /app/src/go/
COPY generated/go/ /app/generated/go/

ENV CGO_ENABLED=1
RUN go build -tags 'netgo sqlite_stat4 sqlite_fts5 sqlite_math_functions sqlite_vtable' -ldflags '-extldflags "-static"' -o res-mon



FROM alpine:3.19

RUN mkdir /app && addgroup -S appuser && adduser -S -G appuser -h /app appuser && chown appuser:appuser /app && chmod 500 /app

WORKDIR /app
EXPOSE 8321

CMD ["./res-mon"]
ENTRYPOINT ["/app/entrypoint.sh"]
HEALTHCHECK --interval=1m --timeout=15s --start-period=30s --retries=5 CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8321/ || exit 1

COPY docker/entrypoint.sh /app/entrypoint.sh
RUN chown root:root /app/entrypoint.sh && chmod 500 /app/entrypoint.sh && apk add --no-cache ca-certificates wget su-exec
COPY --from=builder /app/res-mon .