# dbt Artifacts Package

This package builds a mart of tables and views describing the project it is installed in. In pre V1 versions of the package, the artifacts dbt produces were uploaded to the warehouse, hence the name of the package. That's no longer the case, but the name has stuck!

[![Tier 2 — main](https://github.com/brooklyn-data/dbt_artifacts/actions/workflows/main.yml/badge.svg)](https://github.com/brooklyn-data/dbt_artifacts/actions/workflows/main.yml)
[![Tier 3 — release validation](https://github.com/brooklyn-data/dbt_artifacts/actions/workflows/release.yml/badge.svg)](https://github.com/brooklyn-data/dbt_artifacts/actions/workflows/release.yml)
[![Documentation](https://github.com/brooklyn-data/dbt_artifacts/actions/workflows/publish_docs_on_release.yml/badge.svg)](https://github.com/brooklyn-data/dbt_artifacts/actions/workflows/publish_docs_on_release.yml)

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for
how to set up your environment and submit a PR, and
[docs/dev-workflow.md](docs/dev-workflow.md) for the full
feature-to-release flow. Maintainer-specific guidance lives in
[docs/MAINTAINERS.md](docs/MAINTAINERS.md).

## Supported Data Warehouses

The package currently supports

- Databricks :white_check_mark:
- Spark :white_check_mark:
- Snowflake :white_check_mark:
- Google BigQuery :white_check_mark:
- Postgres :white_check_mark:
- SQL Server :white_check_mark:
- Trino :white_check_mark:
- DuckDB :white_check_mark:

Models included:

```
dim_dbt__current_models
dim_dbt__exposures
dim_dbt__models
dim_dbt__seeds
dim_dbt__snapshots
dim_dbt__sources
dim_dbt__tests
fct_dbt__invocations
fct_dbt__model_executions
fct_dbt__seed_executions
fct_dbt__snapshot_executions
fct_dbt__test_executions
```

See the generated [dbt docs site](https://brooklyn-data.github.io/dbt_artifacts/#!/overview) for documentation on each model.

## Supported dbt versions

As of `3.0.0`, the package requires **dbt 1.10 or newer** (dbt Core 1.10+
or the dbt Fusion engine). The package's generic tests pass their arguments
under `arguments:`, which Fusion requires and dbt Core only understands from
1.10. If you're on an older dbt version, pin `dbt_artifacts` to `2.11.1` in
your `packages.yml`:

```yml
packages:
  - package: brooklyn-data/dbt_artifacts
    version: 2.11.1
```

### dbt Fusion engine (dbt 2.x)

The package is compatible with the [dbt Fusion engine](https://docs.getdbt.com/docs/fusion).
CI parses it with Fusion on every pull request (failing on any deprecation
warning), builds the integration project on Fusion against DuckDB on every
pull request, and runs the full Snowflake integration suite on Fusion before
release. Fusion also supports BigQuery and Databricks; the package parses
cleanly against both, but they are not yet integration-tested on Fusion.
Postgres and Trino are experimental in Fusion, and SQL Server and Spark are
not supported by Fusion, so on those warehouses keep using dbt Core.

Fusion runs `on-run-end` hooks for `dbt compile` and `dbt show`, which dbt
Core does not. `upload_results` skips those commands, so the same invocations
are recorded on both engines.

On dbt Core, `upload_results` inserts each dataset inside one transaction on
Snowflake, Postgres, SQL Server and DuckDB, so a dataset's rows appear
together. On Fusion each insert commits on its own, because Fusion doesn't
keep an explicit transaction across the hook's separate queries.

## Quickstart

1. Add this package to your `packages.yml`:

```
packages:
  - package: brooklyn-data/dbt_artifacts
    version: 2.11.1
```

:construction_worker: Make sure to fix at least the **minor** version, to avoid issues when a new release is open. See the notes on upgrading below for more detail.

2. Run `dbt deps` to install the package

3. Add an on-run-end hook to your `dbt_project.yml`

    ```yml
    on-run-end:
      - "{{ dbt_artifacts.upload_results(results) }}"
    ```

    We recommend adding a conditional here so that the upload only occurs in your production environment, such as:

    ```yml
    on-run-end:
      - "{% if target.name == 'prod' %}{{ dbt_artifacts.upload_results(results) }}{% endif %}"
    ```

4. Run the tables!

    ```
    dbt run --select dbt_artifacts
    ```

### Notes on upgrading

Due to the structure of the project, when additional fields are added, the package needs to be re-run to ensure the tables include the new field, or it will simply error on the hook. These changes will always be implemented within a new **minor** version, so make sure that the version you use in `packages.yml` reflects this.

To upgrade and re-build, update the version number within `packages.yml` and then run:

```
dbt deps
dbt run --select dbt_artifacts
```

Make sure this is updated in any database that you use your code base in.

## Configuration

The following configuration can be used to specify where the raw (sources) data is uploaded, and where the dbt models are created:

```yml
models:
  ...
  dbt_artifacts:
    +database: your_destination_database # optional, default is your target database
    +schema: your_destination_schema # optional, default is your target schema
    staging:
      +database: your_destination_database # optional, default is your target database
      +schema: your_destination_schema # optional, default is your target schema
    sources:
      +database: your_sources_database # optional, default is your target database
      +schema: your sources_database # optional, default is your target schema
```

Note that model materializations and `on_schema_change` configs are defined in this package's `dbt_project.yml`, so do not set them globally in your `dbt_project.yml` ([see docs on configuring packages](https://docs.getdbt.com/docs/building-a-dbt-project/package-management#configuring-packages)):

> Configurations made in your dbt_project.yml file will override any configurations in a package (either in the dbt_project.yml file of the package, or in config blocks).

### Environment Variables

If the project is running in dbt Cloud, the following five columns (<https://docs.getdbt.com/docs/dbt-cloud/using-dbt-cloud/cloud-environment-variables#special-environment-variables>) will be automatically populated in the fct_dbt__invocations model:

- dbt_cloud_project_id
- dbt_cloud_job_id
- dbt_cloud_run_id
- dbt_cloud_run_reason_category
- dbt_cloud_run_reason

To capture other environment variables in the fct_dbt__invocations model in the `env_vars` column, add them to the `env_vars` variable in your `dbt_project.yml`. Note that environment variables with secrets (`DBT_ENV_SECRET_`) can't be logged.

```yml
vars:
  env_vars: [
    'ENV_VAR_1',
    'ENV_VAR_2',
    '...'
  ]
```

### dbt Variables

To capture dbt variables in the fct_dbt__invocations model in the `dbt_vars` column, add them to the `dbt_vars` variable in your `dbt_project.yml`.

```yml
vars:
  dbt_vars: [
    'var_1',
    'var_2',
    '...'
  ]
```

## Creating custom marts tables

Multiple modelled `dim` and `fct` models have been provided for ease of use, but we recognise that some use cases may require custom ones. To this end, you can disable all but the raw sources tables using the following in your `dbt_project.yml` file:

```yml
# dbt_project.yml

models:
  dbt_artifacts:
    +enabled: false
    sources:
      +enabled: true
```

In these sources tables, you will find a JSON column `all_results` which contains a JSON blob of the results object used, which you can use in your own analysis:

- exposures
- models
- seeds
- snapshots
- sources
- tests

This column can cause queries to become too long - particularly in BigQuery. Therefore, if you want to disable this column, you can make use of the `dbt_artifacts_exclude_all_results` variable, and set this to `true` in your `dbt_project.yml` file.

```
# dbt_project.yml
vars:
  dbt_artifacts_exclude_all_results: true
```

### Compiled SQL in test executions

`test_executions` stores each test's compiled SQL in `compiled_sql`, so you can rerun a failing test's query without recompiling the project. It adds the length of that SQL to every test execution row, every run. To leave it out (the column stays, with nulls), set `dbt_artifacts_exclude_compiled_sql` to `true`:

```yml
# dbt_project.yml
vars:
  dbt_artifacts_exclude_compiled_sql: true
```

`audit_table_name` holds the table a test writes its failing rows to. It's set only for tests that store failures (`store_failures: true` or `--store-failures`), and null otherwise.

### Skipping manifest dataset upload

By default, every invocation uploads both the execution results (`model_executions`, `seed_executions`, `test_executions`, `snapshot_executions`) and project's manifest datasets (`models`, `seeds`, `snapshots`, `sources`, `tests`, `exposures`). Because manifest datasets are re-inserted on every run, the underlying tables can grow quickly on routine or scheduled runs.

The manifest datasets usually change only when the project code changes, so you can skip uploading them on routine runs and upload them only when code is merged, for example during the build step in CI.

To skip manifest dataset upload, set the `dbt_artifacts_upload_manifest` variable to `false`:

```yml
# dbt_project.yml
vars:
  dbt_artifacts_upload_manifest: false
```

When `false`, only `invocations` and the execution datasets are uploaded. `invocations` is always uploaded regardless of this setting, as it is the parent record that execution rows reference.

The string values `"false"` and `"0"` also turn it off, so the variable can be set from an environment variable:

```yml
# dbt_project.yml
vars:
  dbt_artifacts_upload_manifest: "{{ env_var('DBT_ARTIFACTS_UPLOAD_MANIFEST', 'true') }}"
```

The `dim_` models (for example `dim_dbt__models` and `dim_dbt__current_models`) describe the project as of the most recent run that uploaded the manifest datasets. A model added since then still appears in `fct_dbt__model_executions`, but not in the `dim_` models until the next run with `dbt_artifacts_upload_manifest` set to `true`. Make sure at least one run uploads them, for example the first run after installing or upgrading the package, and every deployment.

Override it to `true` on runs where you want the full project metadata refreshed:

```sh
dbt build --vars '{"dbt_artifacts_upload_manifest": true}'
```

### Upload batch size

The on-run-end hook inserts each dataset in chunks, one `insert` statement per chunk. By default a chunk holds 100 rows for `models` and 5,000 rows for every other dataset. On BigQuery and Trino the defaults are 50 and 300, and 100 for `test_executions`, whose rows include each test's compiled SQL, because their limits on query text length reject larger inserts. On Trino the limit is the `query.max-length` setting, and an insert over it fails with `QUERY_TEXT_TOO_LARGE`.

If an insert still fails because it is too large, or you want fewer statements, set `dbt_artifacts_insert_batch_size`. Its keys are `models`, `default` (every other dataset), or any dataset name, such as `test_executions`. Keys you leave out keep their defaults:

```yml
# dbt_project.yml
vars:
  dbt_artifacts_insert_batch_size:
    models: 25
    default: 1000
```

Values must be whole numbers of at least 1. Strings such as `"25"` also work, so the values can come from environment variables.

## Consumption and observability marts (Snowflake)

On Snowflake the package also builds these views over the uploaded history:

| Model | One row per | Answers |
|---|---|---|
| `dim_dbt__lineage_edges` | parent → child edge in the current graph | What does each model, snapshot and test depend on? Used by the bottleneck and flaky-test marts. |
| `fct_dbt__consumption_daily_detail` | UTC day × meter × materialization × target | How many successful models built (SMB) and active target tables per day, by deployment target? |
| `fct_dbt__consumption_daily` | UTC day × meter | The same, per day. |
| `fct_dbt__consumption_by_model` | month × model | Which models use the most SMB, how often they build, and what reusing them could save. |
| `fct_dbt__consumption_forecast` | month × meter | Month-to-date usage, the projected month-end total, and the day the plan allowance is projected to run out. |
| `fct_dbt__run_health_daily` (and `_detail`, by target) | UTC day | Invocations, node successes, failures, errors and skips, and the success rate. |
| `fct_dbt__model_performance` | UTC day × model | Median and p95 runtime against the same weekday's baseline, flagging regressions. |
| `fct_dbt__dag_bottlenecks_detail` | invocation × model | How long each model waited on the last of its parents to finish. |
| `fct_dbt__dag_bottlenecks` | UTC day × parent model | Which models hold up the most children, and for how long. |
| `fct_dbt__flaky_tests_detail` | flip | A test that failed and then passed the same day with no parent model rebuilt between. |
| `fct_dbt__flaky_tests` | month × test | Flips, executions and flake rate per test. |

### Lookback window

These views read only recent history: by default the last 30 days. Monthly marts start on the first of the month that contains the start of the window, so they never show a partial month. The consumption marts read at least `dbt_artifacts_run_rate_days` (default 28) for the forecast. `fct_dbt__model_performance` reads that many extra days so its first day has a full baseline. `dim_dbt__lineage_edges` reads the window before the latest manifest upload rather than before today, so a project that uploads the manifest rarely still gets its whole graph.

Large projects should use a shorter window. To read all history, set the variable to `null`:

```yml
# dbt_project.yml
vars:
  dbt_artifacts_mart_lookback_days: 7    # or null for all history
```

The value must be a whole number greater than 0. Strings such as `"7"` and `"null"` also work, so it can come from an environment variable.

To turn off marts you don't use, disable them by name. Disable each `_detail` model together with its roll-up:

```yml
# dbt_project.yml
models:
  dbt_artifacts:
    fct_dbt__dag_bottlenecks_detail:
      +enabled: false
    fct_dbt__dag_bottlenecks:
      +enabled: false
```

### Package tests

The package's generic tests (`unique`, `not_null` and range checks on these marts) check the package's own SQL, not your data, and each one re-reads the views it tests, so they ship disabled. To run them, turn them on in your `dbt_project.yml`. The value must be a literal `true`, not a Jinja expression:

```yml
# dbt_project.yml
data_tests:
  dbt_artifacts:
    +enabled: true
```

## Upgrading from 1.x to >=2.0.0

If you were using the following variables:

```yml
vars:
  dbt_artifacts_database: your_db
  dbt_artifacts_schema: your_schema
```

You must now move these to the following model configs:

```yml
models:
  ...
  dbt_artifacts:
    sources:
      +database: your_db
      +schema: your_schema
```

That's because the raw tables are now managed as dbt models. Be aware of any impact that [generate_database_name](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-custom-databases#generate_database_name) and [generate_schema_name](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-custom-schemas#how-does-dbt-generate-a-models-schema-name) macros may have on the final database/schema.

## Migrating From <1.0.0 to >=1.0.0

To migrate your existing data from the `dbt-artifacts` versions <=0.8.0, a helper macro and guide is provided. This migration uses the old `fct_*` and `dim_*` models' data to populate the new sources. The steps to use the macro are as follows:

1. If not already completed, run `dbt run-operation create_dbt_artifacts_tables` to make your source tables.
2. Run `dbt run-operation migrate_from_v0_to_v1 --args '<see-below-for-arguments>'`.
3. Verify that the migration completes successfully.
4. Manually delete any database objects (sources, staging models, tables/views) from the previous `dbt-artifacts` version.

The arguments for `migrate_from_v0_to_v1` are as follows:
| argument      | description                                               |
|-------------- |---------------------------------------------------------- |
| `old_database`  | the database of the <1.0.0 output (`fct_`/`dim_`) models  |
| `old_schema`    | the schema of the <1.0.0 output (`fct_`/`dim_`) models    |
| `new_database`  | the target database that the artifact sources are in      |
| `new_schema`    | the target schema that the artifact sources are in        |

The old and new database/schemas *do not* have to be different, but it is explicitly defined for flexible support.

An example operation is as follows:

```bash
dbt run-operation migrate_from_v0_to_v1 --args '{old_database: analytics, old_schema: dbt_artifacts, new_database: analytics, new_schema: artifact_sources}'
```

## Acknowledgements

Thank you to [Tails.com](https://tails.com/gb/careers/) for initial development and maintenance of this package. On 2021/12/20, the repository was transferred from the Tails.com GitHub organization to Brooklyn Data Co.

The macros in the early versions package were adapted from code shared by [Kevin Chan](https://github.com/KevinC-wk) and [Jonathan Talmi](https://github.com/jtalmi) of [Snaptravel](snaptravel.com).

Thank you for sharing your work with the community!
