#!/bin/sh
set -eu

if [ "${RUN_MIGRATIONS_ON_START:-0}" = "1" ]; then
  ./migrate up
fi

exec "$@"
