#!/usr/bin/env bash
# Install / refresh Python dependencies via uv.
# Idempotent: safe to run repeatedly.
#
# Usage: scripts/ci/setup.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "${repo_root}"

require_cmd uv

banner "Syncing Python dependencies (uv sync)"
uv sync

log "setup complete"
