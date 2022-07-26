{% macro upload_invocations() -%}
    {% set src_dbt_invocations = source('dbt_artifacts', 'invocations') %}

    {% set invocation_values %}
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
        {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(15) }}
    from values
    (
        '{{ invocation_id }}', {# command_invocation_id #}
        '{{ dbt_version }}', {# dbt_version #}
        '{{ project_name }}', {# project_name #}
        '{{ run_started_at }}', {# run_started_at #}
        '{{ flags.WHICH }}', {# dbt_command #}
        '{{ flags.FULL_REFRESH }}', {# full_refresh_flag #}
        '{{ target.profile_name }}', {# target_profile_name #}
        '{{ target.name }}', {# target_name #}
        '{{ target.schema }}', {# target_schema #}
        {{ target.threads }}, {# target_threads #}

        {% if var('include_dbt_cloud_run_details_env_vars') is true %}
            {{ env_var('DBT_CLOUD_PROJECT_ID') }}, {# dbt_cloud_project_id #}
            {{ env_var('DBT_CLOUD_JOB_ID') }}, {# dbt_cloud_job_id #}
            {{ env_var('DBT_CLOUD_RUN_ID') }}, {# dbt_cloud_run_id #}
            '{{ env_var('DBT_CLOUD_RUN_REASON_CATEGORY') }}', {# dbt_cloud_run_reason_category #}
            '{{ env_var('DBT_CLOUD_RUN_REASON') }}' {# dbt_cloud_run_reason #}
        {% else %}
            null, {# dbt_cloud_project_id #}
            null, {# dbt_cloud_job_id #}
            null, {# dbt_cloud_run_id #}
            null, {# dbt_cloud_run_reason_category #}
            null {# dbt_cloud_run_reason #}
        {% endif %}
    )
    {% endset %}

    {{ dbt_artifacts.insert_into_metadata_table(
        schema_name=src_dbt_invocations.schema,
        table_name=src_dbt_invocations.identifier,
        content=invocation_values
        )
    }}
{% endmacro -%}
