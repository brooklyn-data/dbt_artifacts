# Contributing to the dbt Artifacts Package as a Maintainer

> [!NOTE]
> Replace the placeholder identifiers below (`<your-snowflake-account>`,
> `<your-gcp-project>`, etc.) with your team's specifics. The package
> CI uses these via environment variables — no values are baked into
> the repo. Coordinate access to shared test accounts with your team
> in whatever channel your team uses (the project does not assume any
> particular Slack workspace or chat tool).

## General Guidance

- Maintainers can create branches directly on the repo — no need to
  fork. Ask your team for repo permissions if you don't already have
  them.
- If a contributor has a question on a PR, try to answer it promptly.
- If you review a PR and request changes, follow up to see whether
  the contributor needs help. If you don't hear back within a few
  weeks and the fix is small, finish it yourself and merge — leave a
  short note on the PR pointing the original contributor to where
  their work ended up.

## Warehouse set-up for testing

Credentials are read from `integration_test_project/profiles.yml`
via environment variables. Populate `env.sh` (gitignored) and source
it before running tests: `. ./env.sh`.

### Snowflake

Coordinate access to your team's shared test Snowflake account through
your team's normal access-request process.

````
# integration_test_project/env.sh
export DBT_ENV_SECRET_SNOWFLAKE_TEST_ACCOUNT=<your-snowflake-account>
export DBT_ENV_SECRET_SNOWFLAKE_TEST_USER=<your-test-user>
export DBT_ENV_SECRET_SNOWFLAKE_TEST_PASSWORD=<see your team's secret store>
export DBT_ENV_SECRET_SNOWFLAKE_TEST_ROLE=<role with create/usage on the test DB>
export DBT_ENV_SECRET_SNOWFLAKE_TEST_DATABASE=<test database>
export DBT_ENV_SECRET_SNOWFLAKE_TEST_WAREHOUSE=<test warehouse>
````

### Databricks

Get host, HTTP path, and a [personal access token](https://docs.databricks.com/aws/en/dev-tools/auth#personal-access-tokens-for-users)
from your team's Databricks workspace. The
[compute details page](https://docs.databricks.com/aws/en/integrations/compute-details)
shows where to find the host and HTTP path.

````
export DBT_ENV_SECRET_DATABRICKS_HOST=<workspace-id>.cloud.databricks.com
export DBT_ENV_SECRET_DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/<warehouse-id>
export DBT_ENV_SECRET_DATABRICKS_TOKEN=<personal-access-token>
````

### BigQuery

Coordinate access to your team's test GCP project. Authorise BigQuery
locally per
[Google's ADC guide](https://cloud.google.com/docs/authentication/provide-credentials-adc#how-to).

````
# integration_test_project/env.sh
export DBT_ENV_SECRET_GCP_PROJECT=<your-gcp-project>
````

### Postgres, Trino, SQL Server (local)

These run in containers via [`compose.yml`](../compose.yml). You don't
need to `docker run` anything by hand — `scripts/ci/test.sh` brings the
right container up, runs the tests, and tears it down:

```bash
./scripts/ci/test.sh postgres
./scripts/ci/test.sh trino
./scripts/ci/test.sh sqlserver
```

Note: the host-side ports are deliberately non-standard
(`55432`/`58080`/`51433`) so the test stack never collides with a local
Postgres / web app / SQL Server you might be running. See
[`compose.yml`](../compose.yml) header for details. The SQL Server
target also requires the Microsoft ODBC Driver 18 installed on your
host — see [CONTRIBUTING.md](../CONTRIBUTING.md) for install commands.

## How the package works
- The dbt project in the `integration_test_project` is used to test the work that is done in the main folder. If you are running
  any dbt commands, it will be from in here, rather than the outer project.
- Most of the logic for getting the data is included in the `macros` folder. In here there are a number of 
  `upload_individual_datasets/upload_<<table>>.sql` files which have definitions for the individual data sets. You’ll notice
  that there is a default one at the top, and then any adapter specific ones below that. If you are wanting to make changes to tables
  it is likely to be in these files. If you are adding columns, these should be done in the same order as the columns appear in 
  the `macros/upload_results/get_column_name_lists.sql` file.
  ![img.png](/docs/images/img.png)
- Models in the `sources` folder creates empty tables with the correct field names and types. These get run as part of the
  `dbt run` to ensure that there are empty tables to upload results to. These are materialised as tables. You’ll notice that
  it makes use of `type_` macros to ensure types are accurate across each warehouse. The fields in here also need to be the
  same order as the fields in the `macros/upload_results/get_column_name_lists.sql` file, and any new fields must be added
  AT THE BOTTOM of the table.
  ![img_1.png](/docs/images/img_1.png)
- Models in the `staging` and outer folder create views which tidy these source tables up as in a standard dbt project. These
  are also run as part of `dbt run`.
- Once all tables have been built, they need to get updated by a hook - this is why in the instructions, people need to add
  this to their `dbt_project.yml` file. As an example, the hook is defined in `integration_test_project/dbt_project.yml`
  ````
  on-run-end:
  - "{{ dbt_artifacts.upload_results(results) }}"
  ````
- This then runs `macros/upload_results/upload_results` to populate the files by looking at the [run results](https://docs.getdbt.com/reference/artifacts/run-results-json) and using the
  `upload_*.sql` macros to individually create the results.

## Integration Tests

As of the 2026 CI rework, the previous "Approve Integration Tests"
deployment-environment flow has been removed. PR-level CI now runs
**automatically**, without any maintainer approval step, but is also
**scoped to warehouses that don't need secrets** — Postgres, Trino,
SQL Server. Snowflake / BigQuery validation happens automatically after
you merge the PR.

For the full end-to-end flow (what fires on a PR vs. on push to `main`
vs. on a `release-candidate/X.Y.Z` branch), see
[docs/dev-workflow.md](dev-workflow.md). For the underlying design and
threat model, see [specs/ci-rework/README.md](../specs/ci-rework/README.md).

### What you'll see on a PR

| | Where it runs | When |
|---|---|---|
| Postgres, Trino, SQL Server (Docker) | `pr.yml` (Tier 1) | Every PR push |
| Lint, Snowflake, BigQuery | `main.yml` (Tier 2) | After merge to `main` |
| Full warehouse × dbt-version matrix | `release.yml` (Tier 3) | Push to `release-candidate/X.Y.Z` |

### When a Tier 2 failure surfaces after merge

You have two options:

1. Revert the merge commit on `main`.
2. Push a follow-up fix through the normal PR flow (which will run
   Tier 1 on the PR, then Tier 2 on the post-merge push).

## How to test / verify issues locally

> [!NOTE]
> To test a PR opened by an external contributor, add their fork as a
> remote:
> ```
> git remote add their-username https://github.com/their-username/dbt_artifacts
> git fetch their-username
> git checkout their-username/<their-branch>
> ```

### Quick path

1. One-time setup per [CONTRIBUTING.md](../CONTRIBUTING.md): `uv` and
   `docker` installed, `env.sh` populated for any cloud warehouses
   you'll use.
2. Source credentials and run:
   ```bash
   . ./env.sh
   ./scripts/ci/test.sh snowflake        # or bigquery / postgres / trino / sqlserver
   ```
3. Optional: pin a specific dbt version:
   ```bash
   ./scripts/ci/test.sh snowflake 1_10_0
   ```

The script defaults `GITHUB_SHA` to your current git HEAD short SHA
prefixed with `local_`, so your schemas won't collide with CI runs.
You can override it: `export GITHUB_SHA=local_<your-initials>` before
running if you want stable schema names across runs.

### Checking results in the warehouse

```sql
-- Snowflake
use database dev;
select * from dbt_artifacts_test_commit__<github_sha>.<table_name>;

-- (Note: the dbt_version segment of the schema is empty when running
-- the unversioned env, populated when running a pinned env like 1_10_0.)
```

### Testing against `main` before your branch

To verify the diff you're introducing rather than the cumulative state:

```bash
git checkout main && git pull
./scripts/ci/test.sh <warehouse>
# now switch to your branch
git checkout <your-branch>
./scripts/ci/test.sh <warehouse>
```

If you'd like a fully clean rebuild, drop the test schema first:

```sql
drop schema dbt_artifacts_test_commit__<github_sha> cascade;
```

### Testing against multiple dbt versions

`tox` (invoked by `scripts/ci/test.sh`) creates an isolated venv per
env automatically. You no longer need `pyenv virtualenv` or per-version
manual setup — just pass the version:

```bash
./scripts/ci/test.sh snowflake 1_8_0
./scripts/ci/test.sh snowflake 1_11_0
```

See `tox.ini` for the full list of pinned versions per adapter.

## How to release

The release procedure has changed as of the 2026 CI rework. See
[docs/dev-workflow.md → Stage 3 & 4](dev-workflow.md) for the full
walkthrough. Summary:

1. From up-to-date `main`, create `release-candidate/X.Y.Z`.
2. Bump the version on that branch in `dbt_project.yml` and the
   `packages.yml` example in `README.md`. Push.
3. Watch Tier 3 (`release.yml`) — the full warehouse × dbt-version
   matrix runs. ~30–40 minutes.
4. When green, [create a GitHub Release](https://github.com/brooklyn-data/dbt_artifacts/releases/new)
   tagged `X.Y.Z`, targeting the candidate branch.
5. The docs site rebuilds automatically via
   `publish_docs_on_release.yml`. dbt Hub picks up the new tag within
   an hour via [dbt-labs/hubcap](https://github.com/dbt-labs/hubcap)
   (full releases only — see hubcap guidance for pre-releases).
6. Delete the `release-candidate/X.Y.Z` branch unless you anticipate a
   same-day hotfix on the same minor.

Use [semantic versioning](https://semver.org/). New fields are always
at least a minor bump (consumers must re-run `dbt run --select
dbt_artifacts` after upgrading or the on-run-end hook errors).
