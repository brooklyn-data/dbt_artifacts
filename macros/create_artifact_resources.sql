{% macro create_artifact_resources() %}
{% set create_schema_query %}
create schema if not exists {{ var('dbt_artifacts_database') }}.{{ var('dbt_artifacts_schema') }}
{% endset %}

{% set create_stage_query %}
create stage if not exists {{ var('dbt_artifacts_database') }}.{{ var('dbt_artifacts_schema') }}.artifacts_load
file_format = ( type =  json );
{% endset %}

{% set create_table_query %}
create table if not exists {{ var('dbt_artifacts_database') }}.{{ var('dbt_artifacts_schema') }}.{{ var('dbt_artifacts_table') }} (
    data variant,
    generated_at timestamp,
    path string,
    artifact_type string
);

{% endset %}

{% do log("Creating Schema: " ~ create_schema_query, info=True) %}
{% do run_query(create_schema_query) %}

{% do log("Creating Stage: " ~ create_stage_query, info=True) %}
{% do run_query(create_stage_query) %}

{% do log("Creating Table: " ~ create_table_query, info=True) %}
{% do run_query(create_table_query) %}

{% endmacro %}
