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

{% macro trino__type_array() %}
   array(varchar)
{% endmacro %}

{#- NUMERIC -#}%}

{% macro type_numeric() %}
    {{ return(adapter.dispatch('type_numeric', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_numeric() %}
   {{ return(api.Column.translate_type("numeric")) }}
{% endmacro %}

{% macro trino__type_numeric() %}
   double
{% endmacro %}

{#- LONG STRING -#}
{#- For text that can run past 8,000 characters, such as compiled SQL. SQL Server's
    string type is varchar(8000), and a longer value fails the whole insert. -#}

{% macro type_long_string() %}
    {{ return(adapter.dispatch('type_long_string', 'dbt_artifacts')()) }}
{% endmacro %}

{% macro default__type_long_string() %}
   {{ return(api.Column.translate_type("string")) }}
{% endmacro %}

{% macro sqlserver__type_long_string() %}
   varchar(max)
{% endmacro %}
