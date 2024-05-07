{%- macro escape_string(field) -%}
    {{ return(adapter.dispatch('escape_string', 'dbt_artifacts')(field)) }}
{%- endmacro -%}

{%- macro default__escape_string(field) -%}
    {{ field | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}
{%- endmacro -%}

{%- macro dremio__escape_string(field) -%}
    {{ field | replace("'", "''") }}
{%- endmacro -%}
