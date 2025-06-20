#!/usr/bin/env bash
set -euo pipefail

# Determine the available Docker Compose command
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker compose is not installed." >&2
    exit 1
fi

# Load environment variables from .env if present
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +o allexport
fi

# Find all docker-compose files under this directory
mapfile -t COMPOSE_FILES < <(find "$(dirname "$0")" \
    -path "*/.git" -prune -o \
    \( -name 'docker-compose.yml' -o -name 'docker-compose.yaml' \) -print | sort)

if [ ${#COMPOSE_FILES[@]} -eq 0 ]; then
    echo "No docker-compose files found" >&2
    exit 0
fi

for file in "${COMPOSE_FILES[@]}"; do
    dir="$(dirname "$file")"
    echo "Starting services in $dir"
    (cd "$dir" && $COMPOSE_CMD up -d)
done

