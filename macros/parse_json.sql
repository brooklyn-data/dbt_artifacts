{% macro parse_json(field) -%}
  {{ return(adapter.dispatch('parse_json')(field)) }}
{%- endmacro %}

{% macro default__parse_json(field) -%}
    {{ field }}
{%- endmacro %}

{% macro snowflake__parse_json(field) -%}
    parse_json({{ field }})
{%- endmacro %}

{% macro bigquery__parse_json(field) -%}
    parse_json({{ field }})
{%- endmacro %}

