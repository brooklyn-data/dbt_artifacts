{% macro quote_reserved_keywords(column_name) -%}
  {{ return(adapter.dispatch('quote_reserved_keywords')(column_name)) }}
{%- endmacro %}

{% macro default__quote_reserved_keywords(column_name) -%}
    {{ column_name }}
{%- endmacro %}

{% macro snowflake__quote_reserved_keywords(column_name) -%}
    {{ column_name }}
{%- endmacro %}

{% macro spark__quote_reserved_keywords(column_name) -%}
    {{ column_name }}
{%- endmacro %}

{% macro sqlserver__quote_reserved_keywords(column_name) -%}
    {%- set reserved_keywords = ["database", "schema", "name"] -%}
    {%- if column_name in reserved_keywords -%}
    "{{ column_name }}"
    {%- else -%}
    {{ column_name }}
    {%- endif -%}
{%- endmacro %}
