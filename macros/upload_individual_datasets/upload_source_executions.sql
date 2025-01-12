{% macro upload_source_executions(sources) %}
    {{ return(adapter.dispatch('get_source_executions_dml_sql', 'dbt_artifacts')(sources)) }}
{% endmacro %}

{% macro default__get_source_executions_dml_sql(sources) -%}
    {% if sources != [] %}

        {% set source_execution_values %}
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
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(12) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(13) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(14) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(15) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(16) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(17) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(18) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(19) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(20)) }}
        from values
        {% for source in sources -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ source.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ source.thread_id }}', {# thread_id #}
                '{{ source.status }}', {# status #}

                {% set compile_started_at = (source.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {% if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {% set query_completed_at = (source.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {% if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}

                {{ source.execution_time }}, {# total_node_runtime #}
                '{{ source.node.schema }}', {# schema #}
                '{{ source.node.name }}', {# name #}
                '{{ source.node.source_name }}', {# source_name #}
                '{{ source.node.loaded_at_field }}', {# loaded_at_field #}
                {{ source.node.freshness.warn_after.count }}, {# warn_after_count #}
                '{{ source.node.freshness.warn_after.period }}', {# warn_after_period #}
                {{ source.node.freshness.error_after.count }}, {# error_after_count #}
                '{{ source.node.freshness.error_after.period }}', {# error_after_period #}
                '{{ source.max_loaded_at }}', {# max_loaded_at #}
                '{{ source.snapshotted_at }}', {# snapshotted_at #}
                {{ source.age }}, {# age #}
                '{{ tojson(source.adapter_response) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}' {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}
        {% endfor %}
        {% endset %}
        {{ source_execution_values }}
    {% else %}
        {{ return ("") }}
    {% endif %}
{% endmacro -%}


{% macro bigquery__get_source_executions_dml_sql(sources) -%}
    {% if sources != [] %}

        {% set source_execution_values %}
        {% for source in sources -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ source.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ source.thread_id }}', {# thread_id #}
                '{{ source.status }}', {# status #}

                {% set compile_started_at = (source.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {% if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {% set query_completed_at = (source.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {% if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}

                {{ source.execution_time }}, {# total_node_runtime #}
                '{{ source.node.schema }}', {# schema #}
                '{{ source.node.name }}', {# name #}
                '{{ source.node.source_name }}', {# source_name #}
                '{{ source.node.loaded_at_field }}', {# loaded_at_field #}
                '{{ source.node.freshness.warn_after.count }}', {# warn_after_count #}
                '{{ source.node.freshness.warn_after.period }}', {# warn_after_period #}
                '{{ source.node.freshness.error_after.count }}', {# error_after_count #}
                '{{ source.node.freshness.error_after.period }}', {# error_after_period #}
                '{{ source.max_loaded_at }}', {# max_loaded_at #}
                '{{ source.snapshotted_at }}', {# snapshotted_at #}
                {{ source.age }}, {# age #}
                {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(model.adapter_response) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"')) }} {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}
        {% endfor %}
        {% endset %}
        {{ source_execution_values }}
    {% else %}
        {{ return ("") }}
    {% endif %}
{% endmacro -%}


{% macro snowflake__get_source_executions_dml_sql(sources) -%}
    {% if sources != [] %}

        {% set source_execution_values %}
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
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(12) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(13) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(14) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(15) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(16) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(17) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(18) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(19) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(20)) }}
        from values
        {% for source in sources -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ source.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ source.thread_id }}', {# thread_id #}
                '{{ source.status }}', {# status #}

                {% set compile_started_at = (source.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {% if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {% set query_completed_at = (source.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {% if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}

                {{ source.execution_time }}, {# total_node_runtime #}
                '{{ source.node.schema }}', {# schema #}
                '{{ source.node.name }}', {# name #}
                '{{ source.node.source_name }}', {# source_name #}
                '{{ source.node.loaded_at_field }}', {# loaded_at_field #}
                {{ source.node.freshness.warn_after.count }}, {# warn_after_count #}
                '{{ source.node.freshness.warn_after.period }}', {# warn_after_period #}
                {{ source.node.freshness.error_after.count }}, {# error_after_count #}
                '{{ source.node.freshness.error_after.period }}', {# error_after_period #}
                '{{ source.max_loaded_at }}', {# max_loaded_at #}
                '{{ source.snapshotted_at }}', {# snapshotted_at #}
                {{ source.age }}, {# age #}
                '{{ tojson(source.adapter_response) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}' {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}
        {% endfor %}
        {% endset %}
        {{ source_execution_values }}
    {% else %}
        {{ return ("") }}
    {% endif %}
{% endmacro -%}

{% macro postgres__get_source_executions_dml_sql(sources) -%}
    {% if sources != [] %}

        {% set source_execution_values %}
        {% for source in sources -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ source.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ source.thread_id }}', {# thread_id #}
                '{{ source.status }}', {# status #}

                {% set compile_started_at = (source.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {% if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {% set query_completed_at = (source.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {% if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}

                {{ source.execution_time }}, {# total_node_runtime #}
                '{{ source.node.schema }}', {# schema #}
                '{{ source.node.name }}', {# name #}
                '{{ source.node.source_name }}', {# source_name #}
                '{{ source.node.loaded_at_field }}', {# loaded_at_field #}
                '{{ source.node.freshness.warn_after.count }}', {# warn_after_count #}
                '{{ source.node.freshness.warn_after.period }}', {# warn_after_period #}
                '{{ source.node.freshness.error_after.count }}', {# error_after_count #}
                '{{ source.node.freshness.error_after.period }}', {# error_after_period #}
                '{{ source.max_loaded_at }}', {# max_loaded_at #}
                '{{ source.snapshotted_at }}', {# snapshotted_at #}
                {{ source.age }}, {# age #}
                $${{ tojson(model.adapter_response) }}$$ {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}
        {% endfor %}
        {% endset %}
        {{ source_execution_values }}
    {% else %}
        {{ return ("") }}
    {% endif %}
{% endmacro -%}
