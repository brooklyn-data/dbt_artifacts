{#- BOOLEAN -#}

{% macro type_boolean() %}
    {{ return(adapter.dispatch('type_boolean', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_boolean() %}
   {{ return(api.Column.translate_type("boolean")) }}
{% endmacro %}

{#- TIMESTAMP -#}
{% macro type_timestamp() %}
    {{ return(adapter.dispatch('type_timestamp', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_timestamp() %}
   {{ return(api.Column.translate_type("timestamp")) }}
{% endmacro %}

{% macro athena__type_timestamp() %}
    timestamp(6)
{% endmacro %}
{#- JSON -#}

{% macro type_json() %}
    {{ return(adapter.dispatch('type_json', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_json() %}
   {{ return(api.Column.translate_type("string")) }}
{% endmacro %}

{% macro snowflake__type_json() %}
   object
{% endmacro %}

{% macro bigquery__type_json() %}
   json
{% endmacro %}

{#- ARRAY -#}

{% macro type_array() %}
    {{ return(adapter.dispatch('type_array', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_array() %}
   {{ return(api.Column.translate_type("string")) }}
{% endmacro %}

{% macro snowflake__type_array() %}
   array
{% endmacro %}

{% macro bigquery__type_array() %}
   array<string>
{% endmacro %}
