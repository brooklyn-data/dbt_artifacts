# Contributing to the dbt Artifacts Package

Thank you for your interest in contributing! Bug reports, feature
requests, and pull requests are all welcome.

This guide covers how to set up your local environment, run tests, and
submit a change. For an end-to-end walkthrough of how a change makes it
from a feature branch to a tagged release — including which CI workflow
fires at each stage — see [docs/dev-workflow.md](docs/dev-workflow.md).

---

## Reporting bugs

[Open an issue](https://github.com/brooklyn-data/dbt_artifacts/issues/new)
and describe the problem. Include a minimal reproduction if possible.

## Requesting features

[Open an issue](https://github.com/brooklyn-data/dbt_artifacts/issues/new)
and describe the desired behavior. Pull requests welcome.

---

## Setting up your development environment

### Prerequisites

- **`uv`** — Python toolchain. Installs everything Python from
  `pyproject.toml` and `uv.lock`. See https://docs.astral.sh/uv/.
- **`docker`** — required for the Postgres / Trino / SQL Server
  integration tests (they run in containers).
- **Microsoft ODBC Driver 18** — required on the host (not in the
  container) for the SQL Server tests:
  - macOS:
    ```bash
    brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
    brew install msodbcsql18 mssql-tools18
    ```
  - Linux (Debian/Ubuntu):
    ```bash
    sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
    ```

You only need cloud warehouse credentials (Snowflake / BigQuery /
Databricks) if you intend to test against those. Most contributors can
get useful signal from the local-runnable warehouses alone.

### One-time setup

```bash
git clone https://github.com/<your-fork>/dbt_artifacts
cd dbt_artifacts
./scripts/ci/setup.sh        # uv sync — installs tox, dbt adapters, etc.
```

If you have warehouse credentials, copy the template:

```bash
cp integration_test_project/example-env.sh env.sh
# edit env.sh, fill in any credentials you have
. ./env.sh
```

`env.sh` is gitignored. You only need to source it for warehouses that
need credentials — Postgres, Trino, and SQL Server don't.

---

## Running tests

Everything runs through [`scripts/ci/`](scripts/ci/README.md). The same
scripts CI uses are the ones you run locally — there is no separate
"local" command path.

### Lint

```bash
./scripts/ci/lint.sh                          # lint everything in models/
./scripts/ci/lint.sh --fix                    # auto-fix everything
./scripts/ci/lint.sh models/path/file.sql     # lint a single file
./scripts/ci/lint.sh --fix models/path/file.sql
```

> **Note:** Lint currently requires real Snowflake credentials because
> some models call adapter methods at compile time. If you don't have
> Snowflake access, push your branch — a maintainer will see lint
> results after they merge it. (This limitation is tracked in
> [specs §12.2](specs/ci-rework/README.md) for future fix.)

### One warehouse

```bash
./scripts/ci/test.sh postgres                 # Postgres in Docker
./scripts/ci/test.sh trino                    # Trino in Docker
./scripts/ci/test.sh sqlserver                # SQL Server in Docker
./scripts/ci/test.sh snowflake                # cloud — needs creds
./scripts/ci/test.sh bigquery                 # cloud — needs creds
./scripts/ci/test.sh postgres 1_10_0          # pinned dbt version
```

The script handles `docker compose` lifecycle automatically — brings up
containers, waits for healthy, runs the tests, tears down on exit. Pass
`KEEP_COMPOSE=1` if you want to leave containers running after a
failure for debugging.

### Every local warehouse (what Tier 1 CI runs)

```bash
./scripts/ci/test-all-local.sh
```

Loops Postgres + Trino + SQL Server. Continues past individual failures
and prints a summary.

### A subset of dbt models manually

```bash
cd integration_test_project
. ../env.sh
uv run dbt deps
uv run dbt run --select <model_name> --target <warehouse>
```

Default `--target` is set at the top of
`integration_test_project/profiles.yml` — change it if you don't want
to pass `--target` on every command.

---

## What CI will (and won't) do on your PR

| You see on the PR | You see after merge |
|---|---|
| Lint: **not run** (needs Snowflake creds) | Lint |
| Postgres, Trino, SQL Server integration | Same, re-run on merged code |
| Snowflake, BigQuery: **not run** (no fork secrets) | Snowflake + BigQuery |

This is intentional. PRs from forks cannot have access to the
package's warehouse credentials — that's the security model that
replaced the previous `pull_request_target` setup. If you don't have
Snowflake or BigQuery, that's fine; a maintainer will validate those
after merging. Mention in your PR description what you did and didn't
test locally.

See [docs/dev-workflow.md](docs/dev-workflow.md) for the full picture.

---

## Code style

SQL is linted by [SQLFluff](https://sqlfluff.com). Rules and config
live in `tox.ini`. Highlights:

- Lowercase keywords, identifiers, functions
- Leading commas
- No subqueries in `FROM` / `JOIN` — use CTEs

Run `./scripts/ci/lint.sh` before pushing if you can.

---

## Adding a new dataset column

This package has a critical invariant — column order must match in
**three** places, always with new fields appended at the **bottom**:

1. `macros/upload_individual_datasets/upload_<dataset>.sql` (each
   adapter override, not just `default__`)
2. `models/sources/<dataset>.sql` and the matching `.yml`
3. `macros/upload_results/get_column_name_lists.sql`

Then surface the column through `models/staging/stg_dbt__<dataset>.sql`
and any `dim_` / `fct_` model that should expose it.

**Adding a column is always at least a minor version bump** — consumers
must re-run `dbt run --select dbt_artifacts` after upgrading or the hook
will error.

---

## Adding a new adapter

1. Add adapter-specific overrides in `macros/database_specific_helpers/`
   for: `type_helpers`, `parse_json`, `string_functions`,
   `column_identifier`, `generate_surrogate_key`, `get_relation`.
2. Add adapter overrides in each `macros/upload_individual_datasets/upload_*.sql`
   for any SQL that isn't portable.
3. Add a target to `integration_test_project/profiles.yml` and a
   `[testenv:integration_<name>]` block in `tox.ini`.
4. Wire it into the workflow files:
   - Add to the matrix in [`.github/workflows/pr.yml`](.github/workflows/pr.yml)
     if it can run locally in Docker.
   - Add to [`.github/workflows/main.yml`](.github/workflows/main.yml)
     if it requires cloud credentials.
   - Add per-version entries to the matrix in
     [`.github/workflows/release.yml`](.github/workflows/release.yml).

---

## Submitting your PR

1. Fork → clone → branch → make changes → run tests.
2. Open a PR against `main`. Use the PR template.
3. Tier 1 CI runs automatically. Address any failures.
4. A maintainer reviews. Address feedback.
5. Maintainer merges. Tier 2 fires on `main` — they'll let you know if
   anything cloud-warehouse-specific needs follow-up.

For everything beyond merging — release-candidate branches, tagging,
hotfixes — see [docs/MAINTAINERS.md](docs/MAINTAINERS.md) and
[docs/dev-workflow.md](docs/dev-workflow.md).
