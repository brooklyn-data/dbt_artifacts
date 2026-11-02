#!/usr/bin/env bash
# Run the dbt Fusion engine against integration_test_project/ inside Docker.
#
# Usage:
#   scripts/fusion/dbtf.sh [--rebuild] <dbt args...>
#
# Examples:
#   scripts/fusion/dbtf.sh parse --target snowflake
#   scripts/fusion/dbtf.sh build --target snowflake
#   scripts/fusion/dbtf.sh --rebuild --version
#
# The repo is bind-mounted at /work, so the container sees the working tree
# (including uncommitted changes). Credentials are read from the repo-root
# `.env` if present, then forwarded by name with `docker run -e NAME` — this
# handles multi-line values such as the Snowflake private key, which
# `--env-file` cannot.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../ci/_lib.sh"

cd "${repo_root}"

require_cmd docker

image="dbt-artifacts-fusion:local"

if [[ "${1:-}" == "--rebuild" ]]; then
  shift
  docker build -t "${image}" scripts/fusion
elif ! docker image inspect "${image}" >/dev/null 2>&1; then
  docker build -t "${image}" scripts/fusion
fi

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

# profiles.yml embeds DBT_VERSION in the schema name; keep Fusion runs out of
# the schema used by dbt Core runs from the same commit.
export DBT_VERSION="${DBT_VERSION:-fusion}"
export DBT_SEND_ANONYMOUS_USAGE_STATS=False

env_args=()
while IFS= read -r name; do
  env_args+=(-e "${name}")
done < <(compgen -e | grep -E '^(DBT_|GITHUB_SHA|IS_DEVELOPMENT|TEST_ENV_VAR_)')

# profiles.yml lives in the test project, not ~/.dbt.
exec docker run --rm \
  -v "${repo_root}:/work" \
  -e DBT_PROFILES_DIR=/work/integration_test_project \
  "${env_args[@]}" \
  "${image}" "$@"
