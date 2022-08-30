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

{% macro spark__get_create_invocations_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
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
        target_threads INTEGER,
        dbt_cloud_project_id STRING,
        dbt_cloud_job_id STRING,
        dbt_cloud_run_id STRING,
        dbt_cloud_run_reason_category STRING,
        dbt_cloud_run_reason STRING,
        env_vars STRING,
        dbt_vars STRING
    )
    using delta
{%- endmacro %}

{% macro snowflake__get_create_invocations_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
    create table {{database_name}}.{{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        dbt_version STRING,
        project_name STRING,
        run_started_at TIMESTAMP_TZ,
        dbt_command STRING,
        full_refresh_flag BOOLEAN,
        target_profile_name STRING,
        target_name STRING,
        target_schema STRING,
        target_threads INTEGER,
        dbt_cloud_project_id STRING,
        dbt_cloud_job_id STRING,
        dbt_cloud_run_id STRING,
        dbt_cloud_run_reason_category STRING,
        dbt_cloud_run_reason STRING,
        env_vars OBJECT,
        dbt_vars OBJECT
    )
{%- endmacro %}

{% macro bigquery__get_create_invocations_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
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
        target_threads INTEGER,
        dbt_cloud_project_id STRING,
        dbt_cloud_job_id STRING,
        dbt_cloud_run_id STRING,
        dbt_cloud_run_reason_category STRING,
        dbt_cloud_run_reason STRING,
        env_vars JSON,
        dbt_vars JSON
    )
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
        target_threads INTEGER,
        dbt_cloud_project_id STRING,
        dbt_cloud_job_id STRING,
        dbt_cloud_run_id STRING,
        dbt_cloud_run_reason_category STRING,
        dbt_cloud_run_reason STRING,
        env_vars STRING,
        dbt_vars STRING
    )
{%- endmacro %}
