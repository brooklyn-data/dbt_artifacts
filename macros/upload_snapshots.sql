{% macro upload_snapshots(graph) -%}
    {% set snapshots = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "snapshot") %}
        {% do snapshots.append(node) %}
    {% endfor %}
    {% if snapshots != [] %}
        {% set src_dbt_snapshots = source('dbt_artifacts', 'snapshots') %}
        {{ dbt_artifacts.create_snapshots_table_if_not_exists(src_dbt_snapshots.schema, src_dbt_snapshots.identifier) }}

        {% set snapshot_values %}
        select
            $1,
            $2,
            $3,
            $4,
            $5,
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')('$6') }},
            $7,
            $8,
            $9,
            $10
        from values
        {% for snapshot in snapshots -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ snapshot.unique_id }}', {# node_id #}
                '{{ snapshot.database }}', {# database #}
                '{{ snapshot.schema }}', {# schema #}
                '{{ snapshot.name }}', {# name #}
                '{{ tojson(snapshot.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ snapshot.package_name }}', {# package_name #}
                '{{ snapshot.original_file_path }}', {# path #}
                '{{ snapshot.checksum.checksum }}', {# checksum #}
                '{{ snapshot.config.strategy }}' {# strategy #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            schema_name=src_dbt_snapshots.schema,
            table_name=src_dbt_snapshots.identifier,
            content=snapshot_values
            )
        }}
    {% endif %}
{% endmacro -%}
