{% macro upload_seeds(graph) -%}
    {% set seeds = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "seed") %}
        {% do seeds.append(node) %}
    {% endfor %}
    {% if seeds != [] %}
        {% set src_dbt_seeds = source('dbt_artifacts', 'seeds') %}
        {{ dbt_artifacts.create_seeds_table_if_not_exists(src_dbt_seeds.schema, src_dbt_seeds.identifier) }}

        {% set seed_values %}
        select
            $1,
            $2,
            $3,
            $4,
            $5,
            $6,
            $7,
            $8
        from values
        {% for seed in seeds -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ seed.unique_id }}', {# node_id #}
                '{{ seed.database }}', {# database #}
                '{{ seed.schema }}', {# schema #}
                '{{ seed.name }}', {# name #}
                '{{ seed.package_name }}', {# package_name #}
                '{{ seed.original_file_path }}', {# path #}
                '{{ seed.checksum.checksum }}' {# checksum #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            schema_name=src_dbt_seeds.schema,
            table_name=src_dbt_seeds.identifier,
            content=seed_values
            )
        }}
    {% endif %}
{% endmacro -%}
