{% macro drop_test_schema() %}

-- We drop if exists so that it still passes when the db is clean.
{% set drop_schema_query %}
    drop schema if exists {{ target.schema }};
{% endset %}

{% do log("Dropping test schema: " ~ drop_schema_query, info=True) %}
{% do run_query(drop_schema_query) %}

{% endmacro %}
