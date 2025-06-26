{% macro quote_column(identifier) %}
  {{ adapter.quote(identifier) }}
{% endmacro %}
