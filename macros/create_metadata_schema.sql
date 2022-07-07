{% macro create_metadata_schema() -%}
    {{ return(adapter.dispatch('create_metadata_schema', 'dbt_artifacts')()) }}
{%- endmacro %}

{% macro databricks__create_metadata_schema() -%}
    {% set create_schema_query %}
    create schema if not exists {{ var('dbt_artifacts_schema', 'dbt_artifacts') }}
    {% endset %}

    {% do run_query(create_schema_query) %}
{%- endmacro %}
