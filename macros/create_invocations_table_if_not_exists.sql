{% macro create_invocations_table_if_not_exists(database_name, schema_name, table_name) -%}

    {%- if adapter.get_relation(database=database_name, schema=schema_name, identifier=table_name) is none -%}
        {% if database_name %}
        {{ log("Creating table " ~ adapter.quote(database_name ~ "." ~ schema_name ~ "." ~ table_name), info=true) }}
        {% else %}
        {{ log("Creating table " ~ adapter.quote(schema_name ~ "." ~ table_name), info=true) }}
        {% endif %}
        {%- set query -%}
            {{ adapter.dispatch('get_create_invocations_table_if_not_exists_statement', 'dbt_artifacts')(database_name, schema_name, table_name) }}
        {% endset %}
        {%- call statement(auto_begin=True) -%}
            {{ query }}
        {%- endcall -%}
    {%- endif -%}

{%- endmacro %}

{% macro databricks__get_create_invocations_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
    create table {{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        dbt_version STRING,
        project_name STRING,
        run_started_at TIMESTAMP,
        dbt_command STRING,
        full_refresh_flag BOOLEAN,
        target_profile_name STRING,
        target_name STRING,
        target_schema STRING,
        target_threads INTEGER
    )
    using delta
{%- endmacro %}

{% macro default__get_create_invocations_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
    create table {{database_name}}.{{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        dbt_version STRING,
        project_name STRING,
        run_started_at TIMESTAMP,
        dbt_command STRING,
        full_refresh_flag BOOLEAN,
        target_profile_name STRING,
        target_name STRING,
        target_schema STRING,
        target_threads INTEGER
    )
{%- endmacro %}
