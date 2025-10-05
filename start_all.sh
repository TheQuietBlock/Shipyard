#!/usr/bin/env bash
set -euo pipefail

# Name of the stack to deploy
STACK_NAME=${STACK_NAME:-shipyard}

# Load environment variables from .env if present
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +o allexport
fi

# Ensure overlay network for flight tracking exists
if ! docker network inspect radar-network >/dev/null 2>&1; then
    docker network create --driver overlay radar-network
fi

# Find all docker-compose files under this directory
mapfile -t COMPOSE_FILES < <(find "$(dirname "$0")" \
    -path "*/.git" -prune -o \
    \( -name 'docker-compose.yml' -o -name 'docker-compose.yaml' \) -print | sort)

if [ ${#COMPOSE_FILES[@]} -eq 0 ]; then
    echo "No docker-compose files found" >&2
    exit 0
fi

deploy_args=()
for file in "${COMPOSE_FILES[@]}"; do
    deploy_args+=( -c "$file" )
done

echo "Deploying stack '$STACK_NAME' using compose files:" "${COMPOSE_FILES[@]}"
docker stack deploy "${deploy_args[@]}" "$STACK_NAME"

