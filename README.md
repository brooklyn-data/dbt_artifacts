# dbt Artifacts Package
This package builds a mart of tables describing the project it is installed in. In pre V1 versions of the package, the artifacts dbt produces were uploaded to the warehouse, hence the name of the package. That's no longer the case, but the name has stuck!

Models included:

```
dim_dbt__exposures.sql
dim_dbt__models.sql
dim_dbt__seeds.sql
dim_dbt__snapshots.sql
dim_dbt__sources.sql
dim_dbt__tests.sql
fct_dbt__model_executions.sql
fct_dbt__seed_executions.sql
fct_dbt__snapshot_executions.sql
fct_dbt__test_executions.sql
```

See the generated [dbt docs site](https://brooklyn-data.github.io/dbt_artifacts/#!/overview) for documentation on each model.

## Quickstart

1. Add this package to your `packages.yml` following [these instructions](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/)

2. Run `dbt deps` to install the package

3. Add an on-run-end hook to your `dbt_project.yml`: `on-run-end: "{{ dbt_artifacts.upload_results(results) }}"`

4. Create the tables dbt_artifacts uploads to with `dbt run-operation create_dbt_artifacts_tables`

5. Run `dbt build -s dbt_artifacts` as the last step of any existing dbt jobs to ensure that the latest data is always available

## Configuration

The following configuration can be used to specify where the raw data is uploaded, and where the dbt models are created:

```yml
vars:
  dbt_artifacts:
    dbt_artifacts_database: your_db # optional, default is your target database
    dbt_artifacts_schema: your_schema # optional, default is your target schema

models:
  ...
  dbt_artifacts:
    +schema: your_destination_schema # optional, default is your target database
    staging:
      +schema: your_destination_schema # optional, default is your target schema
```

Note that the model materializations are defined in this package's `dbt_project.yml`, so do not set them in your project.
## Acknowledgements
Thank you to [Tails.com](https://tails.com/gb/careers/) for initial development and maintenance of this package. On 2021/12/20, the repository was transferred from the Tails.com GitHub organization to Brooklyn Data Co.

The macros in the early versions package were adapted from code shared by [Kevin Chan](https://github.com/KevinC-wk) and [Jonathan Talmi](https://github.com/jtalmi) of [Snaptravel](snaptravel.com).

Thank you for sharing your work with the community!

## Contributing

### Running the tests

1. Install pipx
```bash
pip install pipx
pipx ensurepath
```

2. Install tox
```bash
pipx install tox
```

3. Copy and paste `integration_test_project/example-env.sh` as `env.sh`. Fill in the missing values. Source the file with `. ./env.sh`.

4. From this directory, run

```
tox -e integration_snowflake # For the Snowflake tests
tox -e integration_databricks # For the Databricks tests
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
