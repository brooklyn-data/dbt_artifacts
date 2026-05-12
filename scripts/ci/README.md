# scripts/ci/

Single source of truth for how `dbt_artifacts` integration tests run.

GitHub Actions workflows in `.github/workflows/` are thin shells that
`checkout → setup → invoke a script here`. Local development invokes the
**same scripts**. There is no second implementation that "almost matches" CI.

See [`specs/ci-rework.md`](../../specs/ci-rework.md) for the design
rationale and the three-tier CI model these scripts feed into.

## Entry points

| Script | Purpose |
|---|---|
| `setup.sh` | `uv sync` — install Python deps. Idempotent. |
| `compose-up.sh [services...]` | Start local DWH containers; wait for healthy. |
| `compose-down.sh` | Tear down containers and volumes. |
| `lint.sh [--fix] [path]` | SQLFluff lint (or fix) on `models/`. |
| `test.sh <warehouse> [<dbt_version>]` | Run integration tests against one warehouse. |
| `test-all-local.sh [<dbt_version>]` | Run `test.sh` for every local-runnable warehouse. |

Supported `<warehouse>` values: `postgres`, `trino`, `sqlserver`, `snowflake`,
`bigquery`, `databricks`, `spark`. The first three run locally via
`compose.yml`; the rest require credentials in env vars.

`<dbt_version>` follows the tox-env naming convention, e.g. `1_9_0`, `1_8_0`.
Omit for the latest supported adapter version.

## Quick start

```bash
# One-time setup
./scripts/ci/setup.sh

# Lint
./scripts/ci/lint.sh

# Test one local warehouse
./scripts/ci/test.sh postgres

# Test every local warehouse (what Tier 1 CI runs)
./scripts/ci/test-all-local.sh

# Test a cloud warehouse (env vars must be set)
. ./env.sh
./scripts/ci/test.sh snowflake
```

## Host ports

The compose stack binds to **non-standard host ports** so it never clashes
with services a developer is already running locally:

| Warehouse | Host port | Container port |
|---|---|---|
| postgres  | `55432` | `5432`  |
| trino     | `58080` | `8080`  |
| sqlserver | `51433` | `1433`  |

`integration_test_project/profiles.yml` is wired to these shifted ports.
You don't need to remember them — every test path is already configured.
If you reach for `psql -h localhost` out of habit, you'll hit your **local**
Postgres, not the test container; that's intentional.

## Host-side prerequisites

- **`uv`** — Python toolchain. See https://docs.astral.sh/uv/.
- **`docker`** — required for `postgres`, `trino`, `sqlserver` paths.
- **Microsoft ODBC Driver 18** — required on the host (not in the SQL Server
  container) for the `sqlserver` warehouse. The dbt-sqlserver adapter runs on
  the host and connects into the container.
  - macOS:
    ```bash
    brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
    brew install msodbcsql18 mssql-tools18
    ```
  - Linux (Debian/Ubuntu):
    ```bash
    sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
    ```
- For **`bigquery`**: either run with workload-identity credentials (CI), or
  `gcloud auth application-default login` locally.

## Conventions for editing these scripts

- `set -euo pipefail` at the top of every script.
- `source _lib.sh` for shared helpers (`require_env`, `require_cmd`,
  `banner`, `die`, `ensure_github_sha`).
- **No GitHub-Actions-isms** (no `$GITHUB_*` vars used as control flow, no
  `::set-output`, no conditional on CI environment). Scripts behave
  identically on a laptop and on a runner.
- Validate required env vars up front with `require_env`.
- Validate required binaries up front with `require_cmd`.
- Always operate from `${repo_root}` (already `cd`'d by `_lib.sh`).
- Per-warehouse cleanup is the responsibility of the script that brought
  state up. Use `trap` for compose teardown so failures don't leak containers.

## Known pre-existing constraints

These are package-level issues surfaced (not introduced) by this script layer.
Tracked for fixing in follow-up work; documented here so they don't surprise
you the first time you run the scripts.

- **Lint requires real Snowflake credentials.** `lint.sh` uses the dbt
  templater against `profiles.yml`'s default target, and some models in
  this package call adapter methods at compile time. You need a valid
  `DBT_ENV_SECRET_SNOWFLAKE_TEST_*` set in your environment. The active CI
  lint workflow does the same — it's not a CI-only requirement.
## Debugging a failed run

Pass `KEEP_COMPOSE=1` to skip the teardown trap, then poke at containers:

```bash
KEEP_COMPOSE=1 ./scripts/ci/test.sh postgres
docker compose ps
docker compose logs postgres
# When done:
./scripts/ci/compose-down.sh
```
