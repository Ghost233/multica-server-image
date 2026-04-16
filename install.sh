#!/bin/sh
set -eu

RAW_BASE_URL="${RAW_BASE_URL:-https://raw.githubusercontent.com/Ghost233/multica-server-image/main}"
INSTALL_DIR="${INSTALL_DIR:-.}"
FORCE="${FORCE:-0}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

download_file() {
  url="$1"
  out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out"
    return
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$out" "$url"
    return
  fi
  echo "missing required command: curl or wget" >&2
  exit 1
}

generate_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return
  fi
  if [ -r /dev/urandom ]; then
    dd if=/dev/urandom bs=32 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n'
    return
  fi
  echo "failed to generate JWT secret" >&2
  exit 1
}

require_cmd docker

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose is not available" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
mkdir -p data/postgres data/uploads

for f in docker-compose.yml .env .env.example start.sh stop.sh restart.sh status.sh update.sh; do
  if [ "$FORCE" != "1" ] && [ -e "$f" ]; then
    echo "refusing to overwrite existing $PWD/$f (set FORCE=1 to override)" >&2
    exit 1
  fi
done

echo "Downloading deployment files into $PWD"
download_file "$RAW_BASE_URL/docker-compose.yml" docker-compose.yml
download_file "$RAW_BASE_URL/.env.example" .env.example
download_file "$RAW_BASE_URL/start.sh" start.sh
download_file "$RAW_BASE_URL/stop.sh" stop.sh
download_file "$RAW_BASE_URL/restart.sh" restart.sh
download_file "$RAW_BASE_URL/status.sh" status.sh
download_file "$RAW_BASE_URL/update.sh" update.sh
chmod +x start.sh stop.sh restart.sh status.sh update.sh
cp .env.example .env

jwt_secret="${JWT_SECRET:-$(generate_secret)}"
multica_tag="${MULTICA_TAG:-latest}"
postgres_db="${POSTGRES_DB:-multica}"
postgres_user="${POSTGRES_USER:-multica}"
postgres_password="${POSTGRES_PASSWORD:-multica}"
backend_port="${BACKEND_PORT:-8080}"
frontend_port="${FRONTEND_PORT:-3000}"
remote_api_url="${REMOTE_API_URL:-http://backend:8080}"

cat > .env <<ENVEOF
MULTICA_TAG=${multica_tag}
POSTGRES_DB=${postgres_db}
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_password}
JWT_SECRET=${jwt_secret}
BACKEND_PORT=${backend_port}
FRONTEND_PORT=${frontend_port}
REMOTE_API_URL=${remote_api_url}
ENVEOF

echo "Starting containers"
./start.sh

echo
echo "Multica containers started."
echo "Frontend: http://localhost:${frontend_port}"
echo "Backend:  http://localhost:${backend_port}"
echo "Files written to: $PWD"
