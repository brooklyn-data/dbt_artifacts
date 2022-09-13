{#- BOOLEAN -#}

{% macro type_boolean() %}
    {{ return(adapter.dispatch('type_boolean', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_boolean() %}
   {{ return(api.Column.translate_type("boolean")) }}
{% endmacro %}

{#- JSON -#}

{% macro type_json() %}
    {{ return(adapter.dispatch('type_json', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_json() %}
   {{ return(api.Column.translate_type("string")) }}
{% endmacro %}

{% macro snowflake__type_json() %}
   OBJECT
{% endmacro %}

{% macro bigquery__type_json() %}
   JSON
{% endmacro %}

{#- ARRAY -#}

{% macro type_array() %}
    {{ return(adapter.dispatch('type_array', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_array() %}
   {{ return(api.Column.translate_type("string")) }}
{% endmacro %}

{% macro snowflake__type_array() %}
   ARRAY
{% endmacro %}

{% macro bigquery__type_array() %}
   ARRAY<string>
{% endmacro %}
