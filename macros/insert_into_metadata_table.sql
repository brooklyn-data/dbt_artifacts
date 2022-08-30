{% macro insert_into_metadata_table(database_name, schema_name, table_name, content) -%}
    {% if content != "" %}
        {{ return(adapter.dispatch('insert_into_metadata_table', 'dbt_artifacts')(database_name, schema_name, table_name, content)) }}
    {% endif %}
{%- endmacro %}

{% macro spark__insert_into_metadata_table(database_name, schema_name, table_name, content) -%}
    {% set insert_into_table_query %}
    insert into {{ schema_name }}.{{ table_name }}
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}
{%- endmacro %}

{% macro snowflake__insert_into_metadata_table(database_name, schema_name, table_name, content) -%}
    {% set insert_into_table_query %}
    insert into {{database_name}}.{{ schema_name }}.{{ table_name }}
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}
{%- endmacro %}

{% macro bigquery__insert_into_metadata_table(database_name, schema_name, table_name, content) -%}

        {% set insert_into_table_query %}
        insert into {{database_name}}.{{ schema_name }}.{{ table_name }}
        VALUES
        {{ content }}
        {% endset %}

        {% do run_query(insert_into_table_query) %}

{%- endmacro %}

