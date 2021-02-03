# Tails.com's dbt Artifacts Package

This package builds `fct_dbt_model_executions` and `fct_dbt_run_results` tables from dbt artifacts loaded into a table. It is compatible with Snowflake only. The models are based off of the v1 schema introduced in dbt 0.19.0: https://docs.getdbt.com/reference/artifacts/dbt-artifacts/#notes

## Generating the source table

This package requires that the source data already exists in a table in Snowflake. How you achieve that will depend on your implementation.

The author recommends generating the source table using the following query to copy from an external stage (in a snowpipe):

```
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

Where the external stage's prefix is a destination for all dbt artifacts.

## Usage

Add the package to your `packages.yml` following the instructions at https://docs.getdbt.com/docs/building-a-dbt-project/package-management/

Configure the required variables in your `dbt_project.yml`:

```
vars:
  dbt_artifacts:
    dbt_artifacts_database: your_db
    dbt_artifacts_schema: your_schema
    dbt_artifacts_table: your_table

models:
  ...
  dbt_artifacts:
    +schema: your_destination_schema
    +materialized: table
    staging:
      +schema: your_destination_schema
      +materialized: view # The staging tables cannot be ephemeral

```

Run `dbt deps` and then run the package specifically to test with `dbt run -m dbt_artifacts`.

The two fct_ tables are both [incremental](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/).

## Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
