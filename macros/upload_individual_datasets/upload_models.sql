{% macro upload_models(models) -%}
    {{ return(adapter.dispatch("get_models_dml_sql", "dbt_artifacts")(models)) }}
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
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(14) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(15)) }}
        from values
        {% for model in models -%}
                {% set model_copy = dbt_artifacts.copy_model(model) -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model_copy.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ model_copy.database }}', {# database #}
                '{{ model_copy.schema }}', {# schema #}
                '{{ model_copy.name }}', {# name #}
                '{{ tojson(model_copy.depends_on.nodes) | replace('\\', '\\\\') }}', {# depends_on_nodes #}
                '{{ model_copy.package_name }}', {# package_name #}
                '{{ model_copy.original_file_path | replace('\\', '\\\\') }}', {# path #}
                '{{ model_copy.checksum.checksum  | replace('\\', '\\\\') }}', {# checksum #}
                '{{ model_copy.config.materialized }}', {# materialization #}
                '{{ tojson(model_copy.tags) }}', {# tags #}
                '{{ tojson(model_copy.config.meta) | replace("\\", "\\\\") | replace("'","\\'") | replace('"', '\\"') }}', {# meta #}
                '{{ model_copy.alias }}', {# alias #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(model_copy) | replace("\\", "\\\\") | replace("'","\\'") | replace('"', '\\"') }}' {# all_results #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ model_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_models_dml_sql(models) -%}
    {% if models != [] %}
        {% set model_values %}
            {% for model in models -%}
                {% set model_copy = dbt_artifacts.copy_model(model) -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ model_copy.unique_id }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ model_copy.database }}', {# database #}
                    '{{ model_copy.schema }}', {# schema #}
                    '{{ model_copy.name }}', {# name #}
                    {{ tojson(model_copy.depends_on.nodes) }}, {# depends_on_nodes #}
                    '{{ model_copy.package_name }}', {# package_name #}
                    '{{ model_copy.original_file_path | replace('\\', '\\\\') }}', {# path #}
                    '{{ model_copy.checksum.checksum | replace('\\', '\\\\') }}', {# checksum #}
                    '{{ model_copy.config.materialized }}', {# materialization #}
                    {{ tojson(model_copy.tags) }}, {# tags #}
                    {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(model_copy.config.meta)) }}, {# meta #}
                    '{{ model_copy.alias }}', {# alias #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(model_copy) | replace("\\", "\\\\") | replace("'","\\'") | replace('"', '\\"')) }} {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ model_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro postgres__get_models_dml_sql(models) -%}
    {% if models != [] %}
        {% set model_values %}
            {% for model in models -%}
                {% set model_copy = dbt_artifacts.copy_model(model) -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ model_copy.unique_id }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ model_copy.database }}', {# database #}
                    '{{ model_copy.schema }}', {# schema #}
                    '{{ model_copy.name }}', {# name #}
                    '{{ tojson(model_copy.depends_on.nodes) }}', {# depends_on_nodes #}
                    '{{ model_copy.package_name }}', {# package_name #}
                    $${{ model_copy.original_file_path | replace('\\', '\\\\') }}$$, {# path #}
                    '{{ model_copy.checksum.checksum }}', {# checksum #}
                    '{{ model_copy.config.materialized }}', {# materialization #}
                    '{{ tojson(model_copy.tags) }}', {# tags #}
                    $${{ model_copy.config.meta }}$$, {# meta #}
                    '{{ model_copy.alias }}', {# alias #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        $${{ tojson(model_copy) }}$$ {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ model_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}


{% macro sqlserver__get_models_dml_sql(models) -%}

    {% if models != [] %}
        {% set model_values %}
        select
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"
        from ( values
        {% for model in models -%}
                {% set model_copy = dbt_artifacts.copy_model(model) -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model_copy.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ model_copy.database }}', {# database #}
                '{{ model_copy.schema }}', {# schema #}
                '{{ model_copy.name }}', {# name #}
                '{{ tojson(model_copy.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ model_copy.package_name }}', {# package_name #}
                '{{ model_copy.original_file_path }}', {# path #}
                '{{ model_copy.checksum.checksum }}', {# checksum #}
                '{{ model_copy.config.materialized }}', {# materialization #}
                '{{ tojson(model_copy.tags) }}', {# tags #}
                '{{ tojson(model_copy.config.meta) | replace("'","''") }}', {# meta #}
                '{{ model_copy.alias }}', {# alias #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(model_copy) | replace("'","''") }}' {# all_results #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}

        ) v ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15")

        {% endset %}
        {{ model_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

