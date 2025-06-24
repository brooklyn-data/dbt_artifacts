{% macro safe_concat(elements) %}
  {% set adapter = target.type %}
  {% if adapter in ['postgres', 'redshift'] %}
    {{ elements | join(' || ') }}
  {% elif adapter in ['snowflake', 'bigquery', 'databricks', 'trino'] %}
    CONCAT({{ elements | join(', ') }})
  {% elif adapter in ['sqlserver'] %}
    {{ elements | join(' + ') }}
  {% else %}
    -- Fallback to ANSI SQL style
    CONCAT({{ elements | join(', ') }})
  {% endif %}
{% endmacro %}