{% macro begin_transaction() -%}

    {{ return(adapter.dispatch('begin_transaction', 'dbt_artifacts')()) }}

{%- endmacro %}

{% macro default__begin_transaction() -%}
{%- endmacro %}

{% macro snowflake__begin_transaction() -%}

    {% do run_query('begin transaction') %}

{%- endmacro %}

{% macro postgres__begin_transaction() -%}

    {% do run_query('begin') %}

{%- endmacro %}

{% macro sqlserver__begin_transaction() -%}

    {% do run_query('begin transaction') %}

{%- endmacro %}
