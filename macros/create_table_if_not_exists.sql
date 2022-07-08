{% macro create_table_if_not_exists(schema_name, table_name) -%}

    {%- do adapter.create_schema(api.Relation.create(target=database, schema=schema_name)) -%}

    {%- if adapter.get_relation(database=database, schema=schema_name, identifier=table_name) is none -%}
        {{ log("Creating artifact table - "~adapter.quote(database~"."~schema_name~"."~table_name), info=true) }}
        {%- set query -%}
            {{ adapter.dispatch('get_create_table_statement', 'dbt_artifacts')(database, schema_name, table_name) }}
        {% endset %}
        {%- call statement(auto_begin=True) -%}
            {{query}}
        {%- endcall -%}
    {%- endif -%}

{%- endmacro %}

{% macro snowflake__get_create_table_statement(database_name, schema_name, table_name) -%}
    create table {{database_name}}.{{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        was_full_refresh BOOLEAN,
        thread_id STRING,
        status STRING,
        compile_started_at TIMESTAMP,
        query_completed_at TIMESTAMP,
        total_node_runtime INTEGER,
        rows_affected INTEGER,
        model_materialization STRING,
        model_schema STRING,
        name STRING
    )
{%- endmacro %}

{% macro databricks__get_create_table_statement(database_name, schema_name, table_name) -%}
    create table {{database_name}}.{{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        was_full_refresh BOOLEAN,
        thread_id STRING,
        status STRING,
        compile_started_at TIMESTAMP,
        query_completed_at TIMESTAMP,
        total_node_runtime DOUBLE,
        rows_affected INTEGER,
        model_materialization STRING,
        model_schema STRING,
        name STRING
    )
    using delta
{%- endmacro %}

{% macro default__get_create_table_statement(database_name, schema_name, table_name) -%}
    create table {{database_name}}.{{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        was_full_refresh BOOLEAN,
        thread_id STRING,
        status STRING,
        compile_started_at TIMESTAMP,
        query_completed_at TIMESTAMP,
        total_node_runtime INTEGER,
        rows_affected INTEGER,
        model_materialization STRING,
        model_schema STRING,
        name STRING
    )
{%- endmacro %}
