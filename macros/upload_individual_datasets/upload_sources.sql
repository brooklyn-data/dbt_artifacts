{% macro upload_sources(sources) -%}
    {{ return(adapter.dispatch("get_sources_dml_sql", "dbt_artifacts")(sources)) }}
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
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(11)) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(12)) }}
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
                '{{ tojson(source.freshness) | replace("'","\\'") }}', {# freshness #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(source) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}' {# all_results #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ source_values }}
    {% else %} {{ return("") }}
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
                    {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(source.freshness) | replace("'","\\'")) }},  {# freshness #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(source) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"')) }} {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ source_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro postgres__get_sources_dml_sql(sources) -%}
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
                    $${{ source.loaded_at_field }}$$, {# loaded_at_field #}
                    $${{ tojson(source.freshness) }}$$,  {# freshness #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        $${{ tojson(source) }}$$ {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ source_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro clickhouse__get_sources_dml_sql(sources) -%}
{{ return(dbt_artifacts.postgres__get_sources_dml_sql(sources)) }}
{%- endmacro %}

{% macro sqlserver__get_sources_dml_sql(sources) -%}

    {% if sources != [] %}
        {% set source_values %}
        select
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"
        from ( values
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
                '{{ source.loaded_at_field | replace("'","''") }}', {# loaded_at_field #}
                '{{ tojson(source.freshness) | replace("'","''") }}', {# freshness #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(source) | replace("'", "''") }}' {# all_results #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        ) v ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12")
        {% endset %}
        {{ source_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

