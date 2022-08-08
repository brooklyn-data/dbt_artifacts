{% macro create_sources_table_if_not_exists(database_name, schema_name, table_name) -%}

    {%- if adapter.get_relation(database=database_name, schema=schema_name, identifier=table_name) is none -%}
        {% if database_name %}
        {{ log("Creating table " ~ adapter.quote(database_name ~ "." ~ schema_name ~ "." ~ table_name), info=true) }}
        {% else %}
        {{ log("Creating table " ~ adapter.quote(schema_name ~ "." ~ table_name), info=true) }}
        {% endif %}
        {%- set query -%}
            {{ adapter.dispatch('get_create_sources_table_if_not_exists_statement', 'dbt_artifacts')(database_name, schema_name, table_name) }}
        {% endset %}
        {%- call statement(auto_begin=True) -%}
            {{ query }}
        {%- endcall -%}
    {%- endif -%}

{%- endmacro %}

{% macro spark__get_create_sources_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
    create table {{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        run_started_at TIMESTAMP,
        database STRING,
        schema STRING,
        source_name STRING,
        loader STRING,
        name STRING,
        identifier STRING,
        loaded_at_field STRING,
        freshness STRING
    )
    using delta
{%- endmacro %}

{% macro snowflake__get_create_sources_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
    create table {{database_name}}.{{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        run_started_at TIMESTAMP_TZ,
        database STRING,
        schema STRING,
        source_name STRING,
        loader STRING,
        name STRING,
        identifier STRING,
        loaded_at_field STRING,
        freshness ARRAY
    )
{%- endmacro %}

{% macro bigquery__get_create_sources_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
    create table {{database_name}}.{{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        run_started_at TIMESTAMP,
        database STRING,
        schema STRING,
        source_name STRING,
        loader STRING,
        name STRING,
        identifier STRING,
        loaded_at_field STRING,
        freshness JSON
    )
{%- endmacro %}

{% macro default__get_create_sources_table_if_not_exists_statement(database_name, schema_name, table_name) -%}
    create table {{database_name}}.{{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        run_started_at TIMESTAMP,
        database STRING,
        schema STRING,
        source_name STRING,
        loader STRING,
        name STRING,
        identifier STRING,
        loaded_at_field STRING,
        freshness STRING
    )
{%- endmacro %}
