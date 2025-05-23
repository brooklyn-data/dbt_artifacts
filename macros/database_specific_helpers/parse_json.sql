{% macro parse_json(field) -%}
  {{ return(adapter.dispatch('parse_json')(field)) }}
{%- endmacro %}

{% macro default__parse_json(field) -%}
    {{ field }}
{%- endmacro %}

{% macro snowflake__parse_json(field) -%}
    try_parse_json({{ field }})
{%- endmacro %}

{% macro bigquery__parse_json(field) -%}
    safe.parse_json("""{{ field }}""", wide_number_mode=>'round')
{%- endmacro %}

