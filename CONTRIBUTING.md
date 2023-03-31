# Contributing to the dbt Artifacts Package

Thank you for your interest in contributing to the dbt Artifacts Package! We welcome contributions of all kinds,
including bug reports, feature requests, and pull requests. Please read this document to learn how to contribute.

## Reporting Bugs :bug:

If you find a bug, please [open an issue](https://github.com/brooklyn-data/dbt_artifacts/issues/new) and describe the
problem. If possible, include a minimal example that maintainers can use to reproduce the issue. If you are able to
fix the bug, please [open a pull request](https://github.com/github/docs/pulls) with a fix.

## Requesting Features :bulb:

If you would like to request a new feature,
please [open an issue](https://github.com/brooklyn-data/dbt_artifacts/issues/new) and describe the desired behavior.
If you are able to implement the feature, please [open a pull request](https://github.com/github/docs/pulls) with
your changes. If you need help with either of these steps, please let us know!

## Contributing Code :computer:

The high-level flow for contributing code to the dbt Artifacts Package is as follows (see below for details of each stage):

1. Fork the dbt Artifacts Package repository
2. Clone your fork locally
3. Create a new branch
4. Make your changes
5. Run the tests
6. Open a pull request against the `main` branch
7. Make sure your pull request passes all checks
8. Address any review feedback
9. Merge your pull request

The first step to contributing code is
to [fork](https://docs.github.com/en/github/getting-started-with-github/fork-a-repo) the dbt Artifacts Package
repository. Once you have a fork, you can clone it locally and begin making changes.

### Setting up your development environment

#### Running the tests

To run the tests, we use [tox](https://tox.wiki/en/latest/). Tox is a tool that automates testing in multiple Python
environments. Tox is a CLI tool that needs a Python interpreter (version 3.7 or higher) to run. We
recommend [pipx](https://pypa.github.io/pipx/) to install tox into an isolated environment. This has the added benefit
that later you’ll be able to upgrade tox without affecting other parts of the system.

Tox will take care of installing the dependencies for each environment, so you don’t need to worry about that.

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
   If you want to run only tests for a specific database, you can leave the other values blank.

    ```bash
    cp integration_test_project/example-env.sh env.sh
    vim env.sh
    ```

4. Source the file in your current shell context with the command:

   ```bash
   . ./env.sh
   ```

5. From the root directory, run the tests for the databases you have access to below:

    ```
    tox -e integration_snowflake # For the Snowflake tests
    tox -e integration_databricks # For the Databricks tests
    tox -e integration_bigquery # For the BigQuery tests
    ```

The Spark tests require installing the [ODBC driver](https://www.databricks.com/spark/odbc-drivers-download). On a Mac,
DBT_ENV_SPARK_DRIVER_PATH should be set to `/Library/simba/spark/lib/libsparkodbc_sbu.dylib`. Spark tests have not yet
been added to the integration tests.

If you don't have access to a particular database type, this isn't a problem. Test on the one you do have, and let us know in the PR.

#### SQLFluff

We use SQLFluff to keep SQL style consistent. A GitHub action automatically tests pull requests and adds annotations
where there are failures. SQLFluff can also be run locally with `tox`.

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

##### Rules

Enforced rules are defined within `tox.ini`. To view the full list of available rules and their configuration, see
the [SQLFluff documentation](https://docs.sqlfluff.com/en/stable/rules.html).
