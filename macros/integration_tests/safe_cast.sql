{% macro safe_cast(field, sql_type_or_logical) %}
  {% set adapter = target.type %}

  {% set logical_type_map = {
    'string': {
      'postgres': 'TEXT',
      'sqlserver': 'VARCHAR',
      'bigquery': 'STRING',
      'snowflake': 'VARCHAR',
      'databricks': 'STRING',
      'trino': 'VARCHAR'
    },
    'integer': {
      'postgres': 'NUMERIC',
      'sqlserver': 'FLOAT',
      'bigquery': 'FLOAT64',
      'snowflake': 'FLOAT',
      'databricks': 'DOUBLE',
      'trino': 'DOUBLE'
    },
    'date': {
      'postgres': 'DATE',
      'sqlserver': 'DATE',
      'bigquery': 'DATE',
      'snowflake': 'DATE',
      'databricks': 'DATE',
      'trino': 'DATE'
    },
    'timestamp': {
      'postgres': 'TIMESTAMP',
      'sqlserver': 'DATETIME2',
      'bigquery': 'TIMESTAMP',
      'snowflake': 'TIMESTAMP',
      'databricks': 'TIMESTAMP',
      'trino': 'TIMESTAMP'
    }
  } %}

  {% if execute %}
    {% set resolved_type = (
      api.Column.translate_type(sql_type_or_logical)
      if api.Column is defined and api.Column.translate_type is defined
      else logical_type_map.get(sql_type_or_logical, {}).get(adapter, sql_type_or_logical)
    ) %}
  {% else %}
    {% set resolved_type = sql_type_or_logical %}
  {% endif %}

  cast({{ field }} as {{ resolved_type }})

{% endmacro %}
