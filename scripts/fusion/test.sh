#!/usr/bin/env bash
# Run integration tests against a single data warehouse with the dbt Fusion
# engine. The Fusion counterpart of `scripts/ci/test.sh`, running the same
# two-pass build as the tox `integration_<warehouse>` envs.
#
# Usage:
#   scripts/fusion/test.sh <warehouse>
#
# Only warehouses that both this package and Fusion support are accepted.
# Postgres and Trino are experimental in Fusion, and SQL Server / Spark (ODBC)
# are unsupported, so those stay Core-only.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../ci/_lib.sh"

cd "${repo_root}"

if (( $# != 1 )); then
  die "usage: scripts/fusion/test.sh <warehouse>"
fi

warehouse="$1"

# Same as dbtf.sh: pick up local credentials so the env check below sees them.
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

case "${warehouse}" in
  snowflake)
    require_env \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_ACCOUNT \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_USER \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_PRIVATE_KEY \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_ROLE \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_DATABASE \
      DBT_ENV_SECRET_SNOWFLAKE_TEST_WAREHOUSE
    ;;
  *)
    die "unsupported warehouse for Fusion: ${warehouse} (supported: snowflake)"
    ;;
esac

banner "Fusion integration tests (warehouse=${warehouse})"
scripts/fusion/dbtf.sh deps --target "${warehouse}"
scripts/fusion/dbtf.sh build --target "${warehouse}" --exclude-resource-type test
scripts/fusion/dbtf.sh build --target "${warehouse}"

log "fusion test.sh complete: ${warehouse}"
