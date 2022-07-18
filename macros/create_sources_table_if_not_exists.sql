{% macro create_sources_table_if_not_exists(schema_name, table_name) -%}

    {%- do adapter.create_schema(api.Relation.create(target=target.database, schema=schema_name)) -%}

    {%- if adapter.get_relation(database=database, schema=schema_name, identifier=table_name) is none -%}
        {{ log("Creating artifact table - "~adapter.quote(schema_name~"."~table_name), info=true) }}
        {%- set query -%}
            {{ adapter.dispatch('get_create_sources_table_if_not_exists_statement', 'dbt_artifacts')(schema_name, table_name) }}
        {% endset %}
        {%- call statement(auto_begin=True) -%}
            {{ query }}
        {%- endcall -%}
    {%- endif -%}

{%- endmacro %}

{% macro databricks__get_create_sources_table_if_not_exists_statement(schema_name, table_name) -%}
    create table {{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
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

{% macro snowflake__get_create_sources_table_if_not_exists_statement(schema_name, table_name) -%}
    create table {{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
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

{% macro default__get_create_sources_table_if_not_exists_statement(schema_name, table_name) -%}
    create table {{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
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
