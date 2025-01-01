{% macro upload_snapshots(snapshots) -%}

    {{ return(adapter.dispatch("get_snapshots_dml_sql", "dbt_artifacts")(snapshots)) }}

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
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(13) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(14)) }}
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
                '{{ snapshot.checksum.checksum | replace('\\', '\\\\') }}', {# checksum #}
                '{{ snapshot.config.strategy }}', {# strategy #}
                '{{ tojson(snapshot.config.meta) | replace("\\", "\\\\") | replace("'","\\'") | replace('"', '\\"') }}', {# meta #}
                '{{ snapshot.alias }}', {# alias #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(snapshot) | replace("\\", "\\\\") | replace("'","\\'") | replace('"', '\\"') }}' {# all_results #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ snapshot_values }}
    {% else %} {{ return("") }}
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
                    '{{ snapshot.checksum.checksum | replace('\\', '\\\\') }}', {# checksum #}
                    '{{ snapshot.config.strategy }}', {# strategy #}
                    {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(snapshot.config.meta)) }}, {# meta #}
                    '{{ snapshot.alias }}', {# alias #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(snapshot) | replace("\\", "\\\\") | replace("'","\\'") | replace('"', '\\"')) }} {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ snapshot_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro postgres__get_snapshots_dml_sql(snapshots) -%}
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
                    $${{ tojson(snapshot.depends_on.nodes) }}$$, {# depends_on_nodes #}
                    '{{ snapshot.package_name }}', {# package_name #}
                    '{{ snapshot.original_file_path | replace('\\', '\\\\') }}', {# path #}
                    '{{ snapshot.checksum.checksum }}', {# checksum #}
                    '{{ snapshot.config.strategy }}', {# strategy #}
                    $${{ tojson(snapshot.config.meta) }}$$, {# meta #}
                    '{{ snapshot.alias }}', {# alias #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        $${{ tojson(snapshot) }}$$ {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ snapshot_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}


{% macro sqlserver__get_snapshots_dml_sql(snapshots) -%}

    {% if snapshots != [] %}
        {% set snapshot_values %}
        select
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"
        from ( values
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
                '{{ snapshot.original_file_path }}', {# path #}
                '{{ snapshot.checksum.checksum }}', {# checksum #}
                '{{ snapshot.config.strategy }}', {# strategy #}
                '{{ tojson(snapshot.config.meta) | replace("'","''") }}', {# meta #}
                '{{ snapshot.alias }}', {# alias #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(snapshot) | replace("'","''") }}' {# all_results #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}

        ) v ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14")

        {% endset %}
        {{ snapshot_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro clickhouse__get_snapshots_dml_sql(snapshots) -%}
{{ return(dbt_artifacts.postgres__get_snapshots_dml_sql(snapshots)) }}
{%- endmacro %}
