{% macro end_transaction() -%}

    {#- Skipped on the dbt Fusion engine, like begin_transaction. -#}
    {% if dbt_version.startswith('2.') %}
        {{ return('') }}
    {% endif %}

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

{% macro duckdb__end_transaction() -%}

    {{ dbt_artifacts.postgres__end_transaction() }}

{%- endmacro %}

{% macro sqlserver__end_transaction() -%}

    {% do run_query('commit transaction') %}

{%- endmacro %}
