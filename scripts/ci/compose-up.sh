#!/usr/bin/env bash
# Bring up local data warehouse containers and wait for them to be ready.
#
# Usage:
#   scripts/ci/compose-up.sh                # all services
#   scripts/ci/compose-up.sh postgres       # one service (plus its dependencies)
#   scripts/ci/compose-up.sh trino sqlserver
#
# "Ready" means two different things depending on the service type:
#
#   - Long-running services (postgres, trino, sqlserver): brought up with
#     `docker compose up --wait`, which blocks until each service's
#     healthcheck reports healthy.
#
#   - Short-lived init containers (sqlserver-configurator): brought up
#     separately, then waited on with `docker compose wait`, which blocks
#     until the container exits and surfaces its exit code. We can't use
#     `--wait` for these because `--wait` treats "not running" as a failure
#     regardless of exit code — so a container that runs init.sql, exits 0,
#     and is therefore "not running" makes `--wait` return non-zero. That's
#     what was breaking the SQL Server lane on CI runners (the configurator
#     just happens to exit faster on Linux runners than on a dev laptop, so
#     the local race was masking the bug).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "${repo_root}"

require_cmd docker

# Map warehouse short-names to the compose services they require.
# `sqlserver` needs both `sqlserver` itself and the `sqlserver-configurator`
# sidecar that runs `init.sql`.
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

# Split: short-lived init containers vs. long-running healthchecked services.
# Convention: anything matching `*-configurator` is treated as init.
long_running=()
init=()
for svc in "${services[@]}"; do
  if [[ "${svc}" == *-configurator ]]; then
    init+=("${svc}")
  else
    long_running+=("${svc}")
  fi
done

if (( ${#long_running[@]} > 0 )); then
  banner "Starting long-running services: ${long_running[*]}"
  docker compose up -d --wait "${long_running[@]}"
  log "long-running services are healthy"
fi

if (( ${#init[@]} > 0 )); then
  banner "Starting init containers: ${init[*]}"
  docker compose up -d "${init[@]}"
  # `docker compose wait` blocks until each named container exits and
  # returns the highest exit code observed. Failure here means an init
  # script (e.g. SQL Server `init.sql`) errored.
  if ! docker compose wait "${init[@]}"; then
    die "init container(s) failed: ${init[*]} — check 'docker compose logs ${init[*]}'"
  fi
  log "init containers completed successfully"
fi
