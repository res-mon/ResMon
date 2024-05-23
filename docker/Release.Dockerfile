FROM --platform=$BUILDPLATFORM alpine:3.20 as builder

WORKDIR /app

COPY res-mon-linux-amd64 res-mon-linux-arm64 /app/
COPY res-mon-linux-armv7 /app/res-mon-linux-arm

ARG TARGETARCH
RUN mv res-mon-linux-${TARGETARCH} res-mon


FROM alpine:3.20

RUN mkdir /app && addgroup -S appuser && adduser -S -G appuser -h /app appuser && chown appuser:appuser /app && chmod 500 /app

WORKDIR /app
EXPOSE 8321

CMD ["./res-mon"]
ENTRYPOINT ["/app/entrypoint.sh"]
HEALTHCHECK --interval=1m --timeout=15s --start-period=30s --retries=5 CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8321/ || exit 1

COPY docker/entrypoint.sh /app/entrypoint.sh
RUN chown root:root /app/entrypoint.sh && chmod 500 /app/entrypoint.sh && apk add --no-cache ca-certificates wget su-exec
COPY --from=builder /app/res-mon .