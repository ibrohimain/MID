#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/mid}"
cd "$APP_DIR"

echo "==> Building and starting MID stack"
docker compose pull || true
docker compose up -d --build --remove-orphans

echo "==> Status"
docker compose ps
echo "OK: http://$(hostname -I | awk '{print $1}')/"
