{#- BOOLEAN -#}

{% macro type_boolean() %}
    {{ return(adapter.dispatch('type_boolean', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_boolean() %}
   {{ return(api.Column.translate_type("boolean")) }}
{% endmacro %}

{% macro clickhouse__type_boolean() %}
   Nullable(Boolean)
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

{% macro clickhouse__type_json() %}
   Nullable(String)
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

{% macro clickhouse__type_array() %}
   Array(String)
{% endmacro %}

{#- STRING -#}

{% macro type_string() %}
    {{ return(adapter.dispatch('type_string', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_string() %}
  {{ return(api.Column.translate_type("string")) }}
{% endmacro %}

{% macro clickhouse__type_string() %}
  Nullable(String)
{% endmacro %}

{#- TIMESTAMP -#}

{% macro type_timestamp() %}
    {{ return(adapter.dispatch('type_timestamp', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_timestamp() %}
  {{ return(api.Column.translate_type("timestamp")) }}
{% endmacro %}

{% macro clickhouse__type_timestamp() %}
  Nullable(DateTime)
{% endmacro %}

{#- INT -#}

{% macro type_int() %}
    {{ return(adapter.dispatch('type_int', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_int() %}
  {{ return(api.Column.translate_type("integer")) }}
{% endmacro %}

{% macro clickhouse__type_int() %}
  Nullable(Int32)
{% endmacro %}

{#- FLOAT -#}

{% macro type_float() %}
    {{ return(adapter.dispatch('type_float', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_float() %}
  {{ return(api.Column.translate_type("float")) }}
{% endmacro %}

{% macro clickhouse__type_float() %}
  Nullable(Float32)
{% endmacro %}

