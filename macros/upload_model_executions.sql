{% macro upload_model_executions(results) -%}
    {% set models = [] %}
    {% for result in results  %}
        {% if result.node.resource_type == "model" %}
            {% do models.append(result) %}
        {% endif %}
    {% endfor %}
    {{ return(adapter.dispatch('get_model_executions_dml_sql', 'dbt_artifacts')(models)) }}
{%- endmacro %}

{% macro default__get_model_executions_dml_sql(models) -%}
    {% if models != [] %}
        {% set model_execution_values %}
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
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(14) }}
        from values
        {% for model in models -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}

                {% set config_full_refresh = model.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}

                '{{ model.thread_id }}', {# thread_id #}
                '{{ model.status }}', {# status #}

                {% if model.timing != [] %}
                    {% for stage in model.timing if stage.name == "compile" %}
                        {% if loop.length == 0 %}
                            null, {# compile_started_at #}
                        {% else %}
                            '{{ stage.started_at }}', {# compile_started_at #}
                        {% endif %}
                    {% endfor %}

                    {% for stage in model.timing if stage.name == "execute" %}
                        {% if loop.length == 0 %}
                            null, {# query_completed_at #}
                        {% else %}
                            '{{ stage.completed_at }}', {# query_completed_at #}
                        {% endif %}
                    {% endfor %}
                {% else %}
                    null, {# compile_started_at #}
                    null, {# query_completed_at #}
                {% endif %}

                {{ model.execution_time }}, {# total_node_runtime #}
                null, -- rows_affected not available {# Only available in Snowflake & BigQuery #}
                '{{ model.node.config.materialized }}', {# materialization #}
                '{{ model.node.schema }}', {# schema #}
                '{{ model.node.name }}', {# name #}
                '{{ model.node.alias }}' {# alias #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ model_execution_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_model_executions_dml_sql(models) -%}
    {% if models != [] %}
        {% set model_execution_values %}
        {% for model in models -%}
            (
            '{{ invocation_id }}', {# command_invocation_id #}
            '{{ model.node.unique_id }}', {# node_id #}
            '{{ run_started_at }}', {# run_started_at #}

            {% set config_full_refresh = model.node.config.full_refresh %}
            {% if config_full_refresh is none %}
                {% set config_full_refresh = flags.FULL_REFRESH %}
            {% endif %}
            {{ config_full_refresh }}, {# was_full_refresh #}

            '{{ model.thread_id }}', {# thread_id #}
            '{{ model.status }}', {# status #}

            {% if model.timing != [] %}
                {% for stage in model.timing if stage.name == "compile" %}
                    {% if loop.length == 0 %}
                        null, {# compile_started_at #}
                    {% else %}
                        '{{ stage.started_at }}', {# compile_started_at #}
                    {% endif %}
                {% endfor %}

                {% for stage in model.timing if stage.name == "execute" %}
                    {% if loop.length == 0 %}
                        null, {# query_completed_at #}
                    {% else %}
                        '{{ stage.completed_at }}', {# query_completed_at #}
                    {% endif %}
                {% endfor %}
            {% else %}
                null, {# compile_started_at #}
                null, {# query_completed_at #}
            {% endif %}

            {{ model.execution_time }}, {# total_node_runtime #}
            safe_cast('{{ model.adapter_response.rows_affected }}' as int64),
            safe_cast('{{ model.adapter_response.bytes_processed }}' as int64),
            '{{ model.node.config.materialized }}', {# materialization #}
            '{{ model.node.schema }}', {# schema #}
            '{{ model.node.name }}', {# name #}
            '{{ model.node.alias }}' {# alias #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ model_execution_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro snowflake__get_model_executions_dml_sql(models) -%}
    {% if models != [] %}
        {% set model_execution_values %}
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
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(14) }}
        from values
        {% for model in models -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}

                {% set config_full_refresh = model.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}

                '{{ model.thread_id }}', {# thread_id #}
                '{{ model.status }}', {# status #}

                {% if model.timing != [] %}
                    {% for stage in model.timing if stage.name == "compile" %}
                        {% if loop.length == 0 %}
                            null, {# compile_started_at #}
                        {% else %}
                            '{{ stage.started_at }}', {# compile_started_at #}
                        {% endif %}
                    {% endfor %}

                    {% for stage in model.timing if stage.name == "execute" %}
                        {% if loop.length == 0 %}
                            null, {# query_completed_at #}
                        {% else %}
                            '{{ stage.completed_at }}', {# query_completed_at #}
                        {% endif %}
                    {% endfor %}
                {% else %}
                    null, {# compile_started_at #}
                    null, {# query_completed_at #}
                {% endif %}

                {{ model.execution_time }}, {# total_node_runtime #}
                try_cast('{{ model.adapter_response.rows_affected }}' as int), {# rows_affected #}
                '{{ model.node.config.materialized }}', {# materialization #}
                '{{ model.node.schema }}', {# schema #}
                '{{ model.node.name }}', {# name #}
                '{{ model.node.alias }}' {# alias #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ model_execution_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}
