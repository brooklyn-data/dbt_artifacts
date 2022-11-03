{% macro upload_snapshots(graph) -%}
    {% set snapshots = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "snapshot") %}
        {% do snapshots.append(node) %}
    {% endfor %}
    {{ return(adapter.dispatch('get_snapshots_dml_sql', 'dbt_artifacts')(snapshots)) }}

{%- endmacro %}

{% macro default__get_snapshots_dml_sql(snapshots) -%}

    {% if snapshots != [] %}
        {% set snapshot_values %}
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
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(13) }}
        from values
        {% for snapshot in snapshots -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ snapshot.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ snapshot.database }}', {# database #}
                '{{ snapshot.schema }}', {# schema #}
                '{{ snapshot.name }}', {# name #}
                '{{ tojson(snapshot.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ snapshot.package_name }}', {# package_name #}
                '{{ snapshot.original_file_path | replace('\\', '\\\\') }}', {# path #}
                '{{ snapshot.checksum.checksum }}', {# checksum #}
                '{{ snapshot.config.strategy }}', {# strategy #}
                '{{ tojson(snapshot.config.meta) }}', {# meta #}
                '{{ snapshot.alias }}' {# alias #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ snapshot_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_snapshots_dml_sql(snapshots) -%}
    {% if snapshots != [] %}
        {% set snapshot_values %}
            {% for snapshot in snapshots -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ snapshot.unique_id }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ snapshot.database }}', {# database #}
                    '{{ snapshot.schema }}', {# schema #}
                    '{{ snapshot.name }}', {# name #}
                    {{ tojson(snapshot.depends_on.nodes) }}, {# depends_on_nodes #}
                    '{{ snapshot.package_name }}', {# package_name #}
                    '{{ snapshot.original_file_path | replace('\\', '\\\\') }}', {# path #}
                    '{{ snapshot.checksum.checksum }}', {# checksum #}
                    '{{ snapshot.config.strategy }}', {# strategy #}
                    parse_json('{{ tojson(snapshot.config.meta) }}'), {# meta #}
                    '{{ snapshot.alias }}' {# alias #}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ snapshot_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{%- endmacro %}
