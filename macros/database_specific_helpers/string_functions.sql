{% macro str_left(col, length) %}
    {{ return(adapter.dispatch('str_left', 'dbt_artifacts')(col, length)) }}
{% endmacro %}

{% macro default__str_left(col, length) %}
   left({{ col }}, {{ length }})
{% endmacro %}

{% macro trino__str_left(col, length) %}
    substring({{ col }}, 1, {{ length }})
{% endmacro %}
