{% macro create_metadata_table(table_name) -%}
    {{ return(adapter.dispatch('create_metadata_table', 'dbt_artifacts')(table_name)) }}
{%- endmacro %}

{% macro databricks__create_metadata_table(table_name) -%}
    {% set create_table_query %}
    create table if not exists

    {{ var('dbt_artifacts_schema', 'dbt_artifacts') }}.{{table_name}} (
        command_invocation_id string,
        node_id string,
        was_full_refresh boolean,
        thread_id string,
        status string,
        compile_started_at timestamp,
        query_completed_at timestamp,
        total_node_runtime double,
        rows_affected int,
        model_materialization string,
        model_schema string,
        name string
    )
    using delta
    {% endset %}

    {% do run_query(create_table_query) %}
{%- endmacro %}
