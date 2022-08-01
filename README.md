# dbt Artifacts Package
This package builds a mart of tables and views describing the project it is installed in. In pre V1 versions of the package, the artifacts dbt produces were uploaded to the warehouse, hence the name of the package. That's no longer the case, but the name has stuck!

The package currently supports Databricks and Snowflake.

Models included:

```
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

## Quickstart

1. Add this package to your `packages.yml` following [these instructions](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/)

2. Run `dbt deps` to install the package

3. Add an on-run-end hook to your `dbt_project.yml`: `on-run-end: "{{ dbt_artifacts.upload_results(results) }}"`
(We recommend adding a conditional here so that the upload only occurs in your production environment, such as `on-run-end: "{% if target.name == 'prod' %}{{ dbt_artifacts.upload_results(results) }}{% endif %}"`)

4. Create the tables dbt_artifacts uploads to with `dbt run-operation create_dbt_artifacts_tables`

5. Run your project!

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

If the project is running in dbt Cloud, the following five columns (https://docs.getdbt.com/docs/dbt-cloud/using-dbt-cloud/cloud-environment-variables#special-environment-variables) will be populated in the fct_dbt__invocations model:
- dbt_cloud_project_id
- dbt_cloud_job_id
- dbt_cloud_run_id
- dbt_cloud_run_reason_category
- dbt_cloud_run_reason

To capture other environment variables as a dictionnary field (`env_vars`) in the fct_dbt__invocations model, add the below list variable to the configuration in your `dbt_project.yml` file and list all the environment variables you wish to capture. Note that environment variables with secrets (`DBT_ENV_SECRET_`) can't be logged.
```yml
vars:
  env_vars: [
    'DBT_KEY_1',
    'DBT_KEY_2',
    '...'
  ]
```

To capture project variables as a dictionnary field (`dbt_vars`) in the fct_dbt__invocations model, add the below list variable to the configuration in your `dbt_project.yml` file and list all the variables you wish to capture.
```yml
vars:
  dbt_vars: [
    'var_1',
    'var_2',
    '...'
  ]
```
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

3. Copy and paste the `integration_test_project/example-env.sh` file and save as `env.sh`. Fill in the missing values.

4. Source the file in your current shell context with the command: `. ./env.sh`.

5. From this directory, run

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
