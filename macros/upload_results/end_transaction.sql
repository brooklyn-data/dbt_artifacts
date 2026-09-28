{% macro end_transaction() -%}

    {{ return(adapter.dispatch('end_transaction', 'dbt_artifacts')()) }}

{%- endmacro %}

{% macro default__end_transaction() -%}
{%- endmacro %}

{% macro snowflake__end_transaction() -%}

    {% do run_query('commit') %}

{%- endmacro %}

{% macro postgres__end_transaction() -%}

    {% do run_query('commit') %}

{%- endmacro %}

{% macro sqlserver__end_transaction() -%}

    {% do run_query('commit transaction') %}

{%- endmacro %}
