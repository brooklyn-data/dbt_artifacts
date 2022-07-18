{% macro create_exposures_table_if_not_exists(schema_name, table_name) -%}

    {%- do adapter.create_schema(api.Relation.create(target=target.database, schema=schema_name)) -%}

    {%- if adapter.get_relation(database=database, schema=schema_name, identifier=table_name) is none -%}
        {{ log("Creating table " ~ adapter.quote(schema_name ~ "." ~ table_name), info=true) }}
        {%- set query -%}
            {{ adapter.dispatch('get_create_exposures_table_if_not_exists_statement', 'dbt_artifacts')(schema_name, table_name) }}
        {% endset %}
        {%- call statement(auto_begin=True) -%}
            {{ query }}
        {%- endcall -%}
    {%- endif -%}

{%- endmacro %}

{% macro databricks__get_create_exposures_table_if_not_exists_statement(schema_name, table_name) -%}
    create table {{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        name STRING,
        type STRING,
        owner STRING,
        maturity STRING,
        path STRING,
        description STRING,
        url STRING,
        package_name STRING,
        depends_on_nodes STRING
    )
    using delta
{%- endmacro %}

{% macro snowflake__get_create_exposures_table_if_not_exists_statement(schema_name, table_name) -%}
    create table {{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        name STRING,
        type STRING,
        owner VARIANT,
        maturity STRING,
        path STRING,
        description STRING,
        url STRING,
        package_name STRING,
        depends_on_nodes ARRAY
    )
{%- endmacro %}

{% macro default__get_create_exposures_table_if_not_exists_statement(schema_name, table_name) -%}
    create table {{schema_name}}.{{table_name}} (
        command_invocation_id STRING,
        node_id STRING,
        name STRING,
        type STRING,
        owner STRING,
        maturity STRING,
        path STRING,
        description STRING,
        url STRING,
        package_name STRING,
        depends_on_nodes STRING
    )
{%- endmacro %}
