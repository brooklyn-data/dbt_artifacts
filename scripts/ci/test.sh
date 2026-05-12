#!/usr/bin/env bash
# Run integration tests against a single data warehouse.
#
# This is the single entrypoint that both local development and GitHub Actions
# invoke. Whatever this script does locally is exactly what CI does.
#
# Usage:
#   scripts/ci/test.sh <warehouse> [<dbt_version>]
#
# Examples:
#   scripts/ci/test.sh postgres              # latest supported dbt-postgres
#   scripts/ci/test.sh postgres 1_9_0        # pinned dbt-postgres 1.9.x
#   scripts/ci/test.sh snowflake             # requires Snowflake env vars
#
# Local warehouses (postgres, trino, sqlserver) are started via docker compose
# automatically and torn down on exit. Cloud warehouses (snowflake, bigquery,
# databricks) require env vars to be set; the script validates them up front.
#
# Optional env vars:
#   KEEP_COMPOSE=1   skip the teardown trap (useful for debugging a failed run)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "${repo_root}"

require_cmd uv docker

if (( $# < 1 )); then
  die "usage: scripts/ci/test.sh <warehouse> [<dbt_version>]"
fi

warehouse="$1"
dbt_version="${2:-}"

case "${warehouse}" in
  postgres|trino|sqlserver|snowflake|bigquery|databricks|spark)
    ;;
  *)
    die "unknown warehouse: ${warehouse}"
    ;;
esac

# Resolve the tox env name. Empty dbt_version → no suffix → use the
# `integration_<warehouse>` env, which pulls the highest supported adapter.
if [[ -n "${dbt_version}" ]]; then
  tox_env="integration_${warehouse}_${dbt_version}"
else
  tox_env="integration_${warehouse}"
fi

# Per-warehouse env contract.
case "${warehouse}" in
  snowflake)
    require_env \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_ACCOUNT \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_USER \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_PASSWORD \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_ROLE \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_DATABASE \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_WAREHOUSE
    ;;
  bigquery)
    require_env DBT_ENV_SECRET_GCP_PROJECT
    # GOOGLE_APPLICATION_CREDENTIALS is set by google-github-actions/auth in
    # CI, or by the developer's gcloud login locally. Don't require here —
    # let dbt-bigquery surface a clearer error if it's missing.
    ;;
  databricks)
    require_env \
      DBT_ENV_SECRET_DATABRICKS_HOST \
      DBT_ENV_SECRET_DATABRICKS_HTTP_PATH \
      DBT_ENV_SECRET_DATABRICKS_TOKEN
    ;;
  postgres|trino|sqlserver|spark)
    ;;
esac

# Local warehouses: bring up compose, register teardown.
needs_compose=0
case "${warehouse}" in
  postgres|trino|sqlserver)
    needs_compose=1
    ;;
esac

if (( needs_compose )); then
  "${repo_root}/scripts/ci/compose-up.sh" "${warehouse}"
  if [[ -z "${KEEP_COMPOSE:-}" ]]; then
    # Tear down whether the test passes or fails. KEEP_COMPOSE=1 disables this
    # so you can poke at the container after a failure.
    trap '"${repo_root}/scripts/ci/compose-down.sh" || true' EXIT
  fi
fi

ensure_github_sha
ensure_dbt_version

banner "Running ${tox_env} (warehouse=${warehouse}, dbt_version=${dbt_version:-latest})"

# Export DBT_VERSION so it reaches tox (which then passes it to dbt via
# passenv). Already ensured non-empty default above.
export DBT_VERSION

uv run tox -e "${tox_env}"

log "test.sh complete: ${tox_env}"
