#!/usr/bin/env bash
# Run SQLFluff against the dbt models.
#
# Usage:
#   scripts/ci/lint.sh                         # lint everything in models/
#   scripts/ci/lint.sh models/path/file.sql    # lint a single file
#   scripts/ci/lint.sh --fix                   # auto-fix everything in models/
#   scripts/ci/lint.sh --fix models/path/file.sql

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "${repo_root}"

require_cmd uv

# Lint uses the dbt templater, which compiles every model. Some models in
# this package call adapter methods at compile time (e.g. `run_query`), so
# the templater needs a **real** working connection to the default target
# in profiles.yml — currently `snowflake`. This means linting locally
# requires valid Snowflake credentials in the environment, the same way
# the CI lint workflow injects them from secrets.
#
# The dummies below let `env_var()` resolution succeed for the few targets
# that do *not* introspect at compile time, but if you don't have real
# Snowflake creds set, lint will fail with a clearer "could not connect"
# error rather than a cryptic Jinja env_var miss.
: "${DBT_ENV_SECRET_SNOWFLAKE_TEST_ACCOUNT:=lint-only}"
: "${DBT_ENV_SECRET_SNOWFLAKE_TEST_USER:=lint-only}"
: "${DBT_ENV_SECRET_SNOWFLAKE_TEST_PASSWORD:=lint-only}"
: "${DBT_ENV_SECRET_SNOWFLAKE_TEST_ROLE:=lint-only}"
: "${DBT_ENV_SECRET_SNOWFLAKE_TEST_DATABASE:=lint-only}"
: "${DBT_ENV_SECRET_SNOWFLAKE_TEST_WAREHOUSE:=lint-only}"
: "${GITHUB_SHA:=lint-local}"
export DBT_ENV_SECRET_SNOWFLAKE_TEST_ACCOUNT \
       DBT_ENV_SECRET_SNOWFLAKE_TEST_USER \
       DBT_ENV_SECRET_SNOWFLAKE_TEST_PASSWORD \
       DBT_ENV_SECRET_SNOWFLAKE_TEST_ROLE \
       DBT_ENV_SECRET_SNOWFLAKE_TEST_DATABASE \
       DBT_ENV_SECRET_SNOWFLAKE_TEST_WAREHOUSE \
       GITHUB_SHA

# Parse: optional `--fix` flag, then optional path.
fix=0
if [[ "${1:-}" == "--fix" ]]; then
  fix=1
  shift
fi

if (( fix )); then
  if (( $# == 0 )); then
    banner "sqlfluff fix (all models)"
    uv run tox -e fix_all
  else
    banner "sqlfluff fix: $*"
    uv run tox -e fix -- "$@"
  fi
else
  if (( $# == 0 )); then
    banner "sqlfluff lint (all models)"
    uv run tox -e lint_all
  else
    banner "sqlfluff lint: $*"
    uv run tox -e lint -- "$@"
  fi
fi
