{% macro begin_transaction() -%}

    {#-
        Explicit transactions are skipped on the dbt Fusion engine (dbt 2.x). Its drivers don't keep
        begin, the inserts and commit together in one transaction: on DuckDB the commit fails with
        "cannot commit - no transaction is active" and the upload stops. Without them each insert
        commits on its own, as it did before these macros existed.
    -#}
    {% if dbt_version.startswith('2.') %}
        {{ return('') }}
    {% endif %}

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

{% macro duckdb__begin_transaction() -%}

    {{ dbt_artifacts.postgres__begin_transaction() }}

{%- endmacro %}

{% macro sqlserver__begin_transaction() -%}

    {% do run_query('begin transaction') %}

{%- endmacro %}
