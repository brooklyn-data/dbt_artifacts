{% macro upload_exposures(exposures) -%}
    {{ return(adapter.dispatch("get_exposures_dml_sql", "dbt_artifacts")(exposures)) }}
{%- endmacro %}

{% macro default__get_exposures_dml_sql(exposures) -%}

    {% if exposures != [] %}
        {% set exposure_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(3) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(4) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(5) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(6)) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(7) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(8) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(9) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(10) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(12)) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(13)) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(14)) }}
        from values
        {% for exposure in exposures -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ exposure.unique_id | replace("'","\\'") }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ exposure.name | replace("'","\\'") }}', {# name #}
                '{{ exposure.type }}', {# type #}
                '{{ tojson(exposure.owner) }}', {# owner #}
                '{{ exposure.maturity }}', {# maturity #}
                '{{ exposure.original_file_path | replace('\\', '\\\\') }}', {# path #}
                '{{ exposure.description | replace("'","\\'") }}', {# description #}
                '{{ exposure.url }}', {# url #}
                '{{ exposure.package_name }}', {# package_name #}
                '{{ tojson(exposure.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ tojson(exposure.tags) }}', {# tags #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(exposure) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}' {# all_results #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ exposure_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_exposures_dml_sql(exposures) -%}
    {% if exposures != [] %}
        {% set exposure_values %}
            {% for exposure in exposures -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ exposure.unique_id | replace("'","\\'") }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ exposure.name | replace("'","\\'") }}', {# name #}
                    '{{ exposure.type }}', {# type #}
                    {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(exposure.owner) | replace("'","\\'")) }}, {# owner #}
                    '{{ exposure.maturity }}', {# maturity #}
                    '{{ exposure.original_file_path | replace('\\', '\\\\') }}', {# path #}
                    """{{ exposure.description | replace("'","\\'") }}""", {# description #}
                    '{{ exposure.url }}', {# url #}
                    '{{ exposure.package_name }}', {# package_name #}
                    {{ tojson(exposure.depends_on.nodes) }}, {# depends_on_nodes #}
                    {{ tojson(exposure.tags) }}, {# tags #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(exposure) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"')) }} {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ exposure_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro postgres__get_exposures_dml_sql(exposures) -%}
    {% if exposures != [] %}

        {% set exposure_values %}
            {% for exposure in exposures -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    $${{ exposure.unique_id }}$$, {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    $${{ exposure.name }}$$, {# name #}
                    '{{ exposure.type }}', {# type #}
                    $${{ tojson(exposure.owner) }}$$, {# owner #}
                    '{{ exposure.maturity }}', {# maturity #}
                    $${{ exposure.original_file_path }}$$, {# path #}
                    $${{ exposure.description }}$$, {# description #}
                    '{{ exposure.url }}', {# url #}
                    '{{ exposure.package_name }}', {# package_name #}
                    $${{ tojson(exposure.depends_on.nodes) }}$$, {# depends_on_nodes #}
                    $${{ tojson(exposure.tags) }}$$, {# tags #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        $${{ tojson(exposure) }}$$ {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ exposure_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro sqlserver__get_exposures_dml_sql(exposures) -%}

    {% if exposures != [] %}
        {% set exposure_values %}
        select "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"
        from ( values
        {% for exposure in exposures -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ exposure.unique_id | replace("'","''") }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ exposure.name | replace("'","''") }}', {# name #}
                '{{ exposure.type }}', {# type #}
                '{{ tojson(exposure.owner) }}', {# owner #}
                '{{ exposure.maturity }}', {# maturity #}
                '{{ exposure.original_file_path }}', {# path #}
                '{{ exposure.description | replace("'","''") }}', {# description #}
                '{{ exposure.url }}', {# url #}
                '{{ exposure.package_name }}', {# package_name #}
                '{{ tojson(exposure.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ tojson(exposure.tags) }}', {# tags #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(exposure) | replace("'", "''") }}' {# all_results #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}

        ) v ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14")

        {% endset %}
        {{ exposure_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro clickhouse__get_exposures_dml_sql(exposures) -%}
{{ return(dbt_artifacts.postgres__get_exposures_dml_sql(exposures)) }}
{%- endmacro %}

