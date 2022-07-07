{% macro create_metadata_schema(schema_name) -%}
    {{ return(adapter.dispatch('create_metadata_schema', 'dbt_artifacts')(schema_name)) }}
{%- endmacro %}

{% macro databricks__create_metadata_schema(schema_name) -%}
    {% set create_schema_query %}
    create schema if not exists {{ schema_name }}
    {% endset %}

    {% do run_query(create_schema_query) %}
{%- endmacro %}
