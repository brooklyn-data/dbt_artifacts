{#
    Since folks commonly install dbt_artifacts alongside a myriad of other packages,
    we copy the dbt_utils implementation of the surrogate_key macro so we don't have
    any dependencies to make conflicts worse!

    This version is:
    URL: https://github.com/dbt-labs/dbt-utils/blob/main/macros/sql/generate_surrogate_key.sql
    Commit SHA: eaa0e41b033bdf252eff0ae014ec11888f37ebff
    Date: 2023-04-28
#}

{%- macro generate_surrogate_key(field_list) -%}
    {# Note - update the reference to `dbt_utils` to `dbt_artifacts` here #}
    {{ return(adapter.dispatch('generate_surrogate_key', 'dbt_artifacts')(field_list)) }}
{% endmacro %}

{%- macro default__generate_surrogate_key(field_list) -%}

{# Note - Removed this logic to retain consistency with the previous surrogate_key logic #}
{# {%- if var('surrogate_key_treat_nulls_as_empty_strings', False) -%} #}
{%- set default_null_value = "" -%}
{# {%- else -%}
    {%- set default_null_value = '_dbt_utils_surrogate_key_null_' -%}
{%- endif -%} #}

{%- set fields = [] -%}

{%- for field in field_list -%}

    {%- do fields.append(
        "coalesce(cast(" ~ field ~ " as " ~ dbt.type_string() ~ "), '" ~ default_null_value  ~"')"
    ) -%}

    {%- if not loop.last %}
        {%- do fields.append("'-'") -%}
    {%- endif -%}

{%- endfor -%}

{{ dbt.hash(dbt.concat(fields)) }}

{%- endmacro -%}
