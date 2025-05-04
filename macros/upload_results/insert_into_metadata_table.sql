{% macro insert_into_metadata_table(dataset, fields, content) -%}

    {% if content != "" %}

        {# Get the relation that the results will be uploaded to #}
        {% set dataset_relation = dbt_artifacts.get_relation(dataset) %}
        {# Insert the data into the table #}
        {{ return(adapter.dispatch('insert_into_metadata_table', 'dbt_artifacts')(dataset_relation, fields, content)) }}

    {% endif %}

{%- endmacro %}

{% macro spark__insert_into_metadata_table(relation, fields, content) -%}

    {% set insert_into_table_query %}
    insert into {{ relation }} {{ fields }}
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}

{%- endmacro %}

{% macro snowflake__insert_into_metadata_table(relation, fields, content) -%}

    {% set insert_into_table_query %}
    insert into {{ relation }} {{ fields }}
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}

{%- endmacro %}

{% macro bigquery__insert_into_metadata_table(relation, fields, content) -%}

    {% set insert_into_table_query %}
    insert into {{ relation }} {{ fields }}
    values
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}

{%- endmacro %}

{%- endmacro %}

{% macro postgres__insert_into_metadata_table(relation, fields, content) -%}

    {% set insert_into_table_query %}
    insert into {{ relation }} {{ fields }}
    values
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}

{%- endmacro %}

{% macro sqlserver__insert_into_metadata_table(relation, fields, content) -%}

    {% set insert_into_table_query %}
    insert into {{ relation }} {{ fields }}
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}

{%- endmacro %}

{% macro clickhouse__insert_into_metadata_table(relation, fields, content) -%}

    {% set insert_into_table_query %}
    insert into {{ relation }} {{ fields }}
    values
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}

{%- endmacro %}

{% macro default__insert_into_metadata_table(relation, fields, content) -%}
{%- endmacro %}

