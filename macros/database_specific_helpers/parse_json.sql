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

{% macro redshift__parse_json(field) %}
    case
        when can_json_parse({{ field }})
            then json_parse({{ field }})
        else
            {{ field }}
    end 
{%- endmacro %}
