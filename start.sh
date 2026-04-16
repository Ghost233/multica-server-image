#!/bin/sh
set -eu

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo ".env not found in $(pwd)" >&2
  exit 1
fi

mkdir -p data/postgres

docker compose --env-file .env up -d
