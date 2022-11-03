{% macro upload_seeds(graph) -%}
    {% set seeds = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "seed") %}
        {% do seeds.append(node) %}
    {% endfor %}
    {{ return(adapter.dispatch('get_seeds_dml_sql', 'dbt_artifacts')(seeds)) }}
{%- endmacro %}

{% macro default__get_seeds_dml_sql(seeds) -%}

    {% if seeds != [] %}
        {% set seed_values %}
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
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(10)) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }}
        from values
        {% for seed in seeds -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ seed.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ seed.database }}', {# database #}
                '{{ seed.schema }}', {# schema #}
                '{{ seed.name }}', {# name #}
                '{{ seed.package_name }}', {# package_name #}
                '{{ seed.original_file_path | replace('\\', '\\\\') }}', {# path #}
                '{{ seed.checksum.checksum }}', {# checksum #}
                '{{ tojson(seed.config.meta) }}', {# meta #}
                '{{ seed.alias }}' {# alias #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ seed_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_seeds_dml_sql(seeds) -%}
    {% if seeds != [] %}
        {% set seed_values %}
            {% for seed in seeds -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ seed.unique_id }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ seed.database }}', {# database #}
                    '{{ seed.schema }}', {# schema #}
                    '{{ seed.name }}', {# name #}
                    '{{ seed.package_name }}', {# package_name #}
                    '{{ seed.original_file_path | replace('\\', '\\\\') }}', {# path #}
                    '{{ seed.checksum.checksum }}', {# checksum #}
                    parse_json('{{ tojson(seed.config.meta) }}'), {# meta #}
                    '{{ seed.alias }}' {# alias #}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ seed_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{%- endmacro %}
