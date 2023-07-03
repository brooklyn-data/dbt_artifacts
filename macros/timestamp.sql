{%- macro cast_as_timestamp(field) -%}
    {{ return(adapter.dispatch('cast_as_timestamp', 'dbt_artifacts')(field)) }}
{%- endmacro -%}

{%- macro default__cast_as_timestamp(field) -%}
    cast({{ field }} as timestamp)
{%- endmacro -%}

{%- macro dremio__cast_as_timestamp(field) -%}
    cast({{ dbt_artifacts.truncate_timestamp(field) }} as timestamp)
{%- endmacro -%}

{%- macro truncate_timestamp(field) -%}
    {%- set pattern = '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{0,3})?)\d*(\+\d{2}:\d{2}|\-\d{2}:\d{2}|Z|[A-Z]{3}|)$' -%}
    concat(regexp_extract('{{ field }}', '{{ pattern }}', 1), regexp_extract('{{ field }}', '{{ pattern }}', 3))
{%- endmacro -%}
