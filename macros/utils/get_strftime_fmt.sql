{% macro get_strftime_format() %}
    {{ return("%Y-%m-%dT%H:%M:%S.%f") }}
{% endmacro %}
