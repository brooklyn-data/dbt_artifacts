{% macro column_identifier(column_index) -%}
  {{ return(adapter.dispatch('column_identifier')(column_index)) }}
{%- endmacro %}

{% macro default__column_identifier(column_index) -%}
    {{ column_index }}
{%- endmacro %}

{% macro snowflake__column_identifier(column_index) -%}
    ${{ column_index }}
{%- endmacro %}

{% macro spark__column_identifier(column_index) -%}
    col{{ column_index }}
{%- endmacro %}
