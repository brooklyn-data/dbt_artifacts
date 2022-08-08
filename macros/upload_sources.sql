{% macro upload_sources(graph) -%}
    {% set sources = [] %}
    {% for node in graph.sources.values() %}
        {% do sources.append(node) %}
    {% endfor %}
    {{ return(adapter.dispatch('get_sources_dml_sql', 'dbt_artifacts')(sources)) }}
{%- endmacro %}

{% macro default__get_sources_dml_sql(sources) -%}

    {% if sources != [] %}
        {% set source_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(3) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(4) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(5) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(6) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(7) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(8) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(9) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(10) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(11)) }}
        from values
        {% for source in sources -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ source.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ source.database }}', {# database #}
                '{{ source.schema }}', {# schema #}
                '{{ source.source_name }}', {# source_name #}
                '{{ source.loader }}', {# loader #}
                '{{ source.name }}', {# name #}
                '{{ source.identifier }}', {# identifier #}
                '{{ source.loaded_at_field | replace("'","\\'") }}', {# loaded_at_field #}
                '{{ tojson(source.freshness) | replace("'","\\'") }}' {# freshness #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ source_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_sources_dml_sql(sources) -%}
    {% if sources != [] %}
        {% set source_values %}
            {% for source in sources -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ source.unique_id }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ source.database }}', {# database #}
                    '{{ source.schema }}', {# schema #}
                    '{{ source.source_name }}', {# source_name #}
                    '{{ source.loader }}', {# loader #}
                    '{{ source.name }}', {# name #}
                    '{{ source.identifier }}', {# identifier #}
                    '{{ source.loaded_at_field | replace("'","\\'") }}', {# loaded_at_field #}
                    parse_json('{{ tojson(source.freshness) | replace("'","\\'") }}')  {# freshness #}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ source_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{%- endmacro %}
