{# dbt doesn't like us ref'ing in an operation so we fetch the info from the graph #}

{% macro upload_results(results) -%}

    {% if execute %}

        {% if results != [] %}
            {{ dbt_artifacts.upload_execution_results(results) }}
        {% endif %}

        {{ dbt_artifacts.upload_static_artifacts() }}

    {% endif %}

{%- endmacro %}
