#!/usr/bin/env bash
# Bring up local data warehouse containers and wait for them to be healthy.
#
# Usage:
#   scripts/ci/compose-up.sh                # all services
#   scripts/ci/compose-up.sh postgres       # one service (plus its dependencies)
#   scripts/ci/compose-up.sh trino sqlserver
#
# Uses `docker compose up --wait`, which exits 0 only when every requested
# service is healthy (or has run-to-completion successfully, in the case of
# the sqlserver-configurator init job).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "${repo_root}"

require_cmd docker

# Map the warehouse short-name a user might pass to its compose service set.
# `sqlserver` requires the configurator sidecar to run init.sql.
services=()
if (( $# == 0 )); then
  services=(postgres trino sqlserver sqlserver-configurator)
else
  for svc in "$@"; do
    case "${svc}" in
      sqlserver)
        services+=(sqlserver sqlserver-configurator)
        ;;
      postgres|trino|sqlserver-configurator)
        services+=("${svc}")
        ;;
      *)
        die "unknown service: ${svc} (valid: postgres, trino, sqlserver)"
        ;;
    esac
  done
fi

banner "Starting services: ${services[*]}"
docker compose up -d --wait "${services[@]}"

log "all requested services are healthy"
