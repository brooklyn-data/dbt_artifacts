{% macro upload_models(graph) -%}
    {% set models = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "model") %}
        {% do models.append(node) %}
    {% endfor %}
    {{ return(adapter.dispatch('get_models_dml_sql', 'dbt_artifacts')(models)) }}
{%- endmacro %}

{% macro default__get_models_dml_sql(models) -%}

    {% if models != [] %}
        {% set model_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(3) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(4) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(5) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(6) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(7)) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(8) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(9) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(10) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(12)) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(13)) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(14) }}
        from values
        {% for model in models -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ model.database }}', {# database #}
                '{{ model.schema }}', {# schema #}
                '{{ model.name }}', {# name #}
                '{{ tojson(model.depends_on.nodes) | replace('\\', '\\\\') }}', {# depends_on_nodes #}
                '{{ model.package_name }}', {# package_name #}
                '{{ model.original_file_path | replace('\\', '\\\\') }}', {# path #}
                '{{ model.checksum.checksum }}', {# checksum #}
                '{{ model.config.materialized }}', {# materialization #}
                '{{ tojson(model.tags) }}', {# tags #}
                '{{ tojson(model.config.meta) }}', {# meta #}
                '{{ model.alias }}' {# alias #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ model_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_models_dml_sql(models) -%}
    {% if models != [] %}
        {% set model_values %}
            {% for model in models -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ model.unique_id }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ model.database }}', {# database #}
                    '{{ model.schema }}', {# schema #}
                    '{{ model.name }}', {# name #}
                    {{ tojson(model.depends_on.nodes) }}, {# depends_on_nodes #}
                    '{{ model.package_name }}', {# package_name #}
                    '{{ model.original_file_path | replace('\\', '\\\\') }}', {# path #}
                    '{{ model.checksum.checksum }}', {# checksum #}
                    '{{ model.config.materialized }}', {# materialization #}
                    {{ tojson(model.tags) }}, {# tags #}
                    parse_json('{{ tojson(model.config.meta) }}'), {# meta #}
                    '{{ model.alias }}' {# alias #}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ model_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{%- endmacro %}
