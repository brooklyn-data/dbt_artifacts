# dbt Artifacts Package
This package builds a mart of tables from dbt artifacts loaded into a table. It is compatible with Snowflake only. The models are compatible with [the v1-v4 artifact schemas](https://docs.getdbt.com/reference/artifacts/dbt-artifacts/#notes).

Models included:

- `dim_dbt__current_models`
- `dim_dbt__exposures`
- `dim_dbt__models`
- `dim_dbt__seeds`
- `dim_dbt__snapshots`
- `dim_dbt__sources`
- `dim_dbt__tests`
- `fct_dbt__critical_path`
- `fct_dbt__exposures_updates`
- `fct_dbt__latest_full_model_executions`
- `fct_dbt__model_executions`
- `fct_dbt__run_results`
- `fct_dbt__seed_executions`
- `fct_dbt__snapshot_executions`
- `fct_dbt__test_executions`

See the generated [dbt docs site](https://brooklyn-data.github.io/dbt_artifacts/#!/overview) for documentation on each model.

## Installation

1. Add this package to your `packages.yml` following [these instructions](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/)

2. Configure the following variables in your `dbt_project.yml`:

```yml
vars:
  dbt_artifacts:
    dbt_artifacts_database: your_db # optional, default is your target database
    dbt_artifacts_schema: your_schema # optional, default is 'dbt_artifacts'
    dbt_artifacts_table: your_table # optional, default is 'artifacts'
    dbt_artifacts_results_table: your_table # optional, default is 'dbt_run_results'
    dbt_artifacts_result_nodes_table: your_table # optional, default is 'dbt_run_result_nodes'
    dbt_artifacts_manifest_nodes_table: your_table # optional, default is 'dbt_manifest_nodes'

models:
  ...
  dbt_artifacts:
    +schema: your_destination_schema
    staging:
      +schema: your_destination_schema

```
Note that the model materializations are defined in this package's `dbt_project.yml`, so do not set them in your project.

3. Run `dbt deps`.

## Uploading the artifacts
This package uploads the artifact files into Snowflake. There are two methods of doing this:
- V2 (recommended) - flattens the uploaded artifacts on load. This supports artifact files over
  16MB (the limit of a variant field in snowflake) and also makes full refreshes of the
  models much faster because the flattening is done once on load. This method uses three tables:
  `dbt_run_results`, `dbt_run_results_nodes`, and `dbt_manifest_nodes`. To learn more
  about migrating from a V1 setup to a V2 setup - see the section below.
- V1 - uploads the artifacts in their raw form into a single table. This affords more flexibility
  in their use, but is subject to field size limits and higher compute loads to reprocess the
  large JSON payloads in future. This may be appropriate for more custom setups or for small projects
  but for large projects which aren't extending the functionality of the package significantly, we
  recommend the V2 method.

### Option 1: Loading local files [V1 & V2 upload methods]
Snowflake makes it possible to load local files into your warehouse. We've included a number of macros to assist with this. This method can be used by both dbt Cloud users, and users of other orchestration tools.

1. To initially create these tables, execute `dbt run-operation create_artifact_resources`
   ([source](macros/create_artifact_resources.sql)). This will create a stage and a set of tables in
   the `{{ target.database }}.dbt_artifacts` schema — you can override the database, schema and table
   names using the variables listed in the Installation section, above.

2. Add [operations](https://docs.getdbt.com/docs/building-a-dbt-project/hooks-operations/#operations)
   to your production run to load files into your table. The [--no-write-json](https://docs.getdbt.com/reference/global-configs#writing-json-artifacts) flag ensures that no
   artifacts are overwritten by the run-operation prior to uploading.

   **V2 Macro**: Use the `upload_dbt_artifacts_v2` macro ([source](macros/upload_artifacts.sql)). Run the macro after `build`, `run`, `test`, `seed` and `snapshot` operations.
   ```txt
   $ dbt build
   $ dbt --no-write-json run-operation upload_dbt_artifacts_v2
   ```

   **V1 Macro**: Use the `upload_dbt_artifacts` macro ([source](macros/upload_artifacts.sql)). You'll need
   to specify which files to upload through use of the `--args` flag. Here's an example setup.
   ```txt
   $ dbt seed
   $ dbt --no-write-json run-operation upload_dbt_artifacts --args '{filenames: [manifest, run_results]}'

   $ dbt run
   $ dbt --no-write-json run-operation upload_dbt_artifacts --args '{filenames: [manifest, run_results]}'

   $ dbt test
   $ dbt --no-write-json run-operation upload_dbt_artifacts --args '{filenames: [run_results]}'

   $ dbt source snapshot-freshness
   $ dbt --no-write-json run-operation upload_dbt_artifacts --args '{filenames: [sources]}'

   $ dbt docs generate
   $ dbt --no-write-json run-operation upload_dbt_artifacts --args '{filenames: [catalog]}'
   ```

### Option 2: Loading cloud storage files [V1 upload method only]

If using a non-dbt Cloud orchestrator, you might upload the artifacts to cloud storage. Link the cloud storage destination to a Snowflake external stage, and use a snowpipe to copy these files into the 'V1' source table:

```sql
copy into ${snowflake_table.dbt_artifacts.database}.${snowflake_table.dbt_artifacts.schema}.${snowflake_table.dbt_artifacts.name}
from (
    select
    $1 as data,
    $1:metadata:generated_at::timestamp_tz as generated_at,
    metadata$filename as path,
    regexp_substr(metadata$filename, '([a-z_]+.json)$') as artifact_type
    from @${snowflake_stage.dbt_artifacts.database}.${snowflake_stage.dbt_artifacts.schema}.${snowflake_stage.dbt_artifacts.name}
)
file_format = (type = 'JSON')
```

## Running the models
Run `dbt build` (or `dbt run`). You can also run the package specifically with `dbt build -s dbt_artifacts`.

### Migration from V1 upload method to V2.

If you've been running using the V1 upload for some time, you'll have built up a meaningfully
large single artifacts table. This can make the full refresh performance of this package slow
as all the artifacts have to be flattened on each run. V2 overcomes this by flattening the artifacts
on load. A migration script is provided to transition existing V1 artifacts to V2 format.

> It is recommended to make a backup of the artifact table before attempting this process.

1. Upgrade the `dbt_artifacts` package to a version of at least `0.8.0` to ensure all the
   required features for this process are present.

2. Run `dbt run-operation create_artifact_resources` to create the V2 artifact source tables.

3. Update your regular build processes to use the `upload_dbt_artifacts_v2` macro instead
   of `upload_dbt_artifacts` so that any new artifacts are loaded in the new format.

4. Run `dbt run-operation migrate_artifacts_v1_to_v2` to migrate your existing artifacts into the
   new format. This operation can take some time on larger projects and if it fails can leave your
   project in a state that is difficult to roll back from, so take a backup of your original artifacts table.

5. _[Optionally]_ Run the `dedupe_dbt_artifacts_v2` to remove any duplicate records in the
   V2 artifact tables. Historically, V1 artifacts are deduplicated _on read_, but V2 artifacts
   are deduplicated on load and assume no duplicates are present in the tables.

6. Run `dbt run` or `dbt build` to update your dbt artifact models based on the V2 source tables.

## Acknowledgements
Thank you to [Tails.com](https://tails.com/gb/careers/) for initial development and maintenance of this package. On 2021/12/20, the repository was transferred from the Tails.com GitHub organization to Brooklyn Data Co.

The macros in this package have been adapted from code shared by [Kevin Chan](https://github.com/KevinC-wk) and [Jonathan Talmi](https://github.com/jtalmi) of [Snaptravel](snaptravel.com).

Thank you for sharing your work with the community!

## Contributing

### Tests

Install pipx:
```bash
pip install pipx
pipx ensurepath
```

Install tox:
```bash
pipx install tox
```

Create a dbt profile named `dbt_artifacts` which dbt can use to test the package. From this directory, run:

```
tox -e integration
```

### SQLFluff

We use SQLFluff to keep SQL style consistent. A GitHub action automatically tests pull requests and adds annotations where there are failures. SQLFluff can also be run locally with `tox`. To install tox, we recommend using `pipx`.

Install pipx:
```bash
pip install pipx
pipx ensurepath
```

Install tox:
```bash
pipx install tox
```

Lint all models in the /models directory:
```bash
tox
```

Fix all models in the /models directory:
```bash
tox -e fix_all
```

Lint (or subsitute lint to fix) a specific model:
```bash
tox -e lint -- models/path/to/model.sql
```

Lint (or subsitute lint to fix) a specific directory:
```bash
tox -e lint -- models/path/to/directory
```

#### Rules

Enforced rules are defined within `tox.ini`. To view the full list of available rules and their configuration, see the [SQLFluff documentation](https://docs.sqlfluff.com/en/stable/rules.html).
