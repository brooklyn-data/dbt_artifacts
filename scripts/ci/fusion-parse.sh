#!/usr/bin/env bash
# Fusion compatibility check that needs no warehouse credentials.
#
# Usage:
#   scripts/ci/fusion-parse.sh
#
# Parses integration_test_project/ (and therefore this package) with the dbt
# Fusion engine and fails on any warning, so deprecations Fusion reports as
# "will error post preview" fail CI before they become hard errors. Fusion's
# parse never connects to the warehouse, so dummy profile values are enough;
# this is what lets it run in the no-secrets PR tier.
#
# Fusion runs from PyPI through uv (tox env fusion_parse; the version is
# pinned in tox.ini), so this needs uv and nothing else.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "${repo_root}"

require_cmd uv

for var in \
  DBT_ENV_SECRET_SNOWFLAKE_TEST_ACCOUNT \
  DBT_ENV_SECRET_SNOWFLAKE_TEST_USER \
  DBT_ENV_SECRET_SNOWFLAKE_TEST_PRIVATE_KEY \
  DBT_ENV_SECRET_SNOWFLAKE_TEST_ROLE \
  DBT_ENV_SECRET_SNOWFLAKE_TEST_DATABASE \
  DBT_ENV_SECRET_SNOWFLAKE_TEST_WAREHOUSE; do
  export "${var}=${!var:-dummy}"
done
export GITHUB_SHA="${GITHUB_SHA:-local}"

banner "Fusion parse (snowflake target, --warn-error)"
uv run tox -e fusion_parse

log "fusion parse complete"
