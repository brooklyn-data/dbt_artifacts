#!/usr/bin/env bash
# Tear down local data warehouse containers and remove their volumes.
#
# Usage: scripts/ci/compose-down.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "${repo_root}"

require_cmd docker

banner "Stopping containers and removing volumes"
docker compose down -v --remove-orphans

log "compose stack torn down"
