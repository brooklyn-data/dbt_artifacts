{% macro upload_test_executions(tests) -%}
    {{ return(adapter.dispatch("get_test_executions_dml_sql", "dbt_artifacts")(tests)) }}
{%- endmacro %}

{% macro default__get_test_executions_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_execution_values %}
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
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(13)) }}
        from values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}

                {% set config_full_refresh = test.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}

                '{{ test.thread_id }}', {# thread_id #}
                '{{ test.status }}', {# status #}

                {% set compile_started_at = (test.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {% if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {% set query_completed_at = (test.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {% if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}

                {{ test.execution_time }}, {# total_node_runtime #}
                null, {# rows_affected not available in Databricks #}
                {{ 'null' if test.failures is none else test.failures }}, {# failures #}
                '{{ test.message | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}', {# message #}
                '{{ tojson(test.adapter_response) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}' {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ test_execution_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_test_executions_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_execution_values %}
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}

                {% set config_full_refresh = test.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                {{ config_full_refresh }}, {# was_full_refresh #}

                '{{ test.thread_id }}', {# thread_id #}
                '{{ test.status }}', {# status #}

                {% set compile_started_at = (test.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {% if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {% set query_completed_at = (test.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {% if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}

                {{ test.execution_time }}, {# total_node_runtime #}
                null, {# rows_affected not available in Databricks #}
                {{ 'null' if test.failures is none else test.failures }}, {# failures #}
                '{{ test.message | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') | replace("\n", "\\n") }}', {# message #}
                {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(test.adapter_response) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"')) }} {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}

        {%- endfor %}
        {% endset %}
        {{ test_execution_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro postgres__get_test_executions_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_execution_values %}
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}

                {% set config_full_refresh = test.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                {{ config_full_refresh }}, {# was_full_refresh #}

                '{{ test.thread_id }}', {# thread_id #}
                '{{ test.status }}', {# status #}

                {% if test.timing != [] %}
                    {% for stage in test.timing if stage.name == "compile" %}
                        {% if loop.length == 0 %}
                            null, {# compile_started_at #}
                        {% else %}
                            '{{ stage.started_at }}', {# compile_started_at #}
                        {% endif %}
                    {% endfor %}

                    {% for stage in test.timing if stage.name == "execute" %}
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

                {{ test.execution_time }}, {# total_node_runtime #}
                null, {# rows_affected not available in Databricks #}
                {{ 'null' if test.failures is none else test.failures }}, {# failures #}
                $${{ test.message  }}$$, {# message #}
                $${{ tojson(test.adapter_response) }}$$ {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}

        {%- endfor %}
        {% endset %}
        {{ test_execution_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro snowflake__get_test_executions_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_execution_values %}
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
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(13)) }}
        from values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}

                {% set config_full_refresh = test.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}

                '{{ test.thread_id }}', {# thread_id #}
                '{{ test.status }}', {# status #}

                {% set compile_started_at = (test.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {% if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {% set query_completed_at = (test.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {% if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}

                {{ test.execution_time }}, {# total_node_runtime #}
                try_cast('{{ test.adapter_response.rows_affected }}' as int), {# rows_affected #}
                {{ 'null' if test.failures is none else test.failures }}, {# failures #}
                '{{ test.message | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}', {# message #}
                '{{ tojson(test.adapter_response) | replace("\\", "\\\\") | replace("'", "\\'") | replace('"', '\\"') }}' {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ test_execution_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro sqlserver__get_test_executions_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_execution_values %}
        select
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13"
        from ( values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}

                {% set config_full_refresh = test.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}

                '{{ test.thread_id }}', {# thread_id #}
                '{{ test.status }}', {# status #}

                {% set compile_started_at = (model.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {% if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {% set query_completed_at = (model.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {% if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}

                {{ test.execution_time }}, {# total_node_runtime #}
                null, {# rows_affected not available in Databricks #}
                {{ 'null' if test.failures is none else test.failures }}, {# failures #}
                '{{ test.message | replace("'", "''") }}', {# message #}
                '{{ tojson(test.adapter_response) | replace("'", "''") }}' {# adapter_response #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}

        ) AS v ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13")

        {% endset %}
        {{ test_execution_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro clickhouse__get_test_executions_dml_sql(tests) -%}
{{ return(dbt_artifacts.postgres__get_test_executions_dml_sql(tests)) }}
{%- endmacro %}
