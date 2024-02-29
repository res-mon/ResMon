#!/bin/sh

mkdir -p /app/data && chown appuser:appuser /app/data && chmod 700 /app/data
touch /app/data/database.db && chown appuser:appuser /app/data/database.db && chmod 600 /app/data/database.db
touch /app/data/database.db-shm && chown appuser:appuser /app/data/database.db-shm && chmod 600 /app/data/database.db-shm
touch /app/data/database.db-wal && chown appuser:appuser /app/data/database.db-wal && chmod 600 /app/data/database.db-wal
chown appuser:appuser res-mon && chmod 500 res-mon

exec gosu appuser:appuser "$@"