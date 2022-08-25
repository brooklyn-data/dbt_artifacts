{% macro upload_snapshots(graph) -%}
    {% set src_dbt_snapshots = source('dbt_artifacts', 'snapshots') %}
    {% set snapshots = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "snapshot") %}
        {% do snapshots.append(node) %}
    {% endfor %}

    {% if snapshots != [] %}
        {% set snapshot_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(3)) }}
        from values
        {% for snapshot in snapshots -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ tojson(snapshot) | replace('\\', '\\\\') | replace("'", "\\'") }}' {# snapshot #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_snapshots.database,
            schema_name=src_dbt_snapshots.schema,
            table_name=src_dbt_snapshots.identifier,
            content=snapshot_values
            )
        }}
    {% endif %}
{% endmacro -%}
