{% macro create_artifact_resources() %}

{% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}

{{ create_schema( src_dbt_artifacts ) }}

{% set create_stage_query %}
create stage if not exists {{ src_dbt_artifacts }}
file_format = ( type =  json );
{% endset %}

{% set create_table_query %}
create table if not exists {{ src_dbt_artifacts }} (
    data variant,
    generated_at timestamp,
    path string,
    artifact_type string
);

{% endset %}


{% do log("Creating Stage: " ~ create_stage_query, info=True) %}
{% do run_query(create_stage_query) %}

{% do log("Creating Table: " ~ create_table_query, info=True) %}
{% do run_query(create_table_query) %}

{% endmacro %}
