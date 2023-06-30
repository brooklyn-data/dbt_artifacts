{%- macro truncate_timestamp(field) -%}
    {{ return(adapter.dispatch('truncate_timestamp', 'dbt_artifacts')(field)) }}
{%- endmacro -%}

{%- macro default__truncate_timestamp(field) -%}
    {{ field }}
{%- endmacro -%}

{%- macro dremio__truncate_timestamp(field) -%}
    {%- set pattern = '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{0,3})?)\d*(\+\d{2}:\d{2}|\-\d{2}:\d{2}|Z|[A-Z]{3}|)$' -%}
    concat(regexp_extract('{{ field }}', '{{ pattern }}', 1), regexp_extract('{{ field }}', '{{ pattern }}', 3))
{%- endmacro -%}
