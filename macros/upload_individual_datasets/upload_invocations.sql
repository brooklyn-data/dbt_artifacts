{% macro upload_invocations() -%}

    {# Need to remove keys with results that can't be handled properly #}
    {# warn_error_options - returns a python object in 1.5 #}
    {% if "warn_error_options" in invocation_args_dict %}
        {% if invocation_args_dict.warn_error_options is not string %}
            {% if invocation_args_dict.warn_error_options.include %}
                {% set include_options = invocation_args_dict.warn_error_options.include %}
            {% else %} {% set include_options = "" %}
            {% endif %}
            {% if invocation_args_dict.warn_error_options.exclude %}
                {% set exclude_options = invocation_args_dict.warn_error_options.exclude %}
            {% else %} {% set exclude_options = "" %}
            {% endif %}
            {% set warn_error_options = {"include": include_options, "exclude": exclude_options} %}
            {%- do invocation_args_dict.update({"warn_error_options": warn_error_options}) %}
        {% endif %}
    {% endif %}

    {% if "event_time_start" in invocation_args_dict and invocation_args_dict.strftime is not none %}
        {% do invocation_args_dict.update(
            {"event_time_start": invocation_args_dict.event_time_start.strftime(dbt_artifacts.get_strftime_format())}
        ) %}
    {% endif %}
    {% if "event_time_end" in invocation_args_dict and invocation_args_dict.strftime is not none %}
        {% do invocation_args_dict.update(
            {"event_time_end": invocation_args_dict.event_time_end.strftime(dbt_artifacts.get_strftime_format())}
        ) %}
    {% endif %}

    {{ log(invocation_args_dict) }}
    {{ return(adapter.dispatch("get_invocations_dml_sql", "dbt_artifacts")()) }}
{%- endmacro %}

{% macro default__get_invocations_dml_sql() -%}
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
        nullif({{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }}, ''),
        nullif({{ adapter.dispatch('column_identifier', 'dbt_artifacts')(12) }}, ''),
        nullif({{ adapter.dispatch('column_identifier', 'dbt_artifacts')(13) }}, ''),
        nullif({{ adapter.dispatch('column_identifier', 'dbt_artifacts')(14) }}, ''),
        nullif({{ adapter.dispatch('column_identifier', 'dbt_artifacts')(15) }}, ''),
        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(16)) }},
        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(17)) }},
        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(18)) }},
        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(19)) }}
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

        '{{ env_var('DBT_CLOUD_PROJECT_ID', '') }}', {# dbt_cloud_project_id #}
        '{{ env_var('DBT_CLOUD_JOB_ID', '') }}', {# dbt_cloud_job_id #}
        '{{ env_var('DBT_CLOUD_RUN_ID', '') }}', {# dbt_cloud_run_id #}
        '{{ env_var('DBT_CLOUD_RUN_REASON_CATEGORY', '') }}', {# dbt_cloud_run_reason_category #}
        '{{ env_var('DBT_CLOUD_RUN_REASON', '') | replace("'","\\'") }}', {# dbt_cloud_run_reason #}

        {% if var('env_vars', none) %}
            {% set env_vars_dict = {} %}
            {% for env_variable in var('env_vars') %}
                {% do env_vars_dict.update({env_variable: (env_var(env_variable, '') | replace("'", "''"))}) %}
            {% endfor %}
            '{{ tojson(env_vars_dict) }}', {# env_vars #}
        {% else %}
            null, {# env_vars #}
        {% endif %}

        {% if var('dbt_vars', none) %}
            {% set dbt_vars_dict = {} %}
            {% for dbt_var in var('dbt_vars') %}
                {% do dbt_vars_dict.update({dbt_var: (var(dbt_var, '') | replace("'", "''"))}) %}
            {% endfor %}
            '{{ tojson(dbt_vars_dict) }}', {# dbt_vars #}
        {% else %}
            null, {# dbt_vars #}
        {% endif %}

        '{{ tojson(invocation_args_dict) | replace('\\', '\\\\') | replace("'", "\\'") }}', {# invocation_args #}

        {% set metadata_env = {} %}
        {% for key, value in dbt_metadata_envs.items() %}
            {% do metadata_env.update({key: (value | replace("'", "''"))}) %}
        {% endfor %}
        '{{ tojson(metadata_env) | replace('\\', '\\\\') }}' {# dbt_custom_envs #}

    )
    {% endset %}
    {{ invocation_values }}

{% endmacro -%}

{% macro bigquery__get_invocations_dml_sql() -%}
    {% set invocation_values %}
        (
        '{{ invocation_id }}', {# command_invocation_id #}
        '{{ dbt_version }}', {# dbt_version #}
        '{{ project_name }}', {# project_name #}
        '{{ run_started_at }}', {# run_started_at #}
        '{{ flags.WHICH }}', {# dbt_command #}
        {{ flags.FULL_REFRESH }}, {# full_refresh_flag #}
        '{{ target.profile_name }}', {# target_profile_name #}
        '{{ target.name }}', {# target_name #}
        '{{ target.schema }}', {# target_schema #}
        {{ target.threads }}, {# target_threads #}

        '{{ env_var('DBT_CLOUD_PROJECT_ID', '') }}', {# dbt_cloud_project_id #}
        '{{ env_var('DBT_CLOUD_JOB_ID', '') }}', {# dbt_cloud_job_id #}
        '{{ env_var('DBT_CLOUD_RUN_ID', '') }}', {# dbt_cloud_run_id #}
        '{{ env_var('DBT_CLOUD_RUN_REASON_CATEGORY', '') }}', {# dbt_cloud_run_reason_category #}
        '{{ env_var('DBT_CLOUD_RUN_REASON', '') | replace("'","\\'") }}', {# dbt_cloud_run_reason #}

        {% if var('env_vars', none) %}
            {% set env_vars_dict = {} %}
            {% for env_variable in var('env_vars') %}
                {% do env_vars_dict.update({env_variable: (env_var(env_variable, ''))}) %}
            {% endfor %}
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(env_vars_dict)) }}, {# env_vars #}
        {% else %}
            null, {# env_vars #}
        {% endif %}

        {% if var('dbt_vars', none) %}
            {% set dbt_vars_dict = {} %}
            {% for dbt_var in var('dbt_vars') %}
                {% do dbt_vars_dict.update({dbt_var: (var(dbt_var, ''))}) %}
            {% endfor %}
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(dbt_vars_dict)) }}, {# dbt_vars #}
        {% else %}
            null, {# dbt_vars #}
        {% endif %}

        {% if invocation_args_dict.vars %}
            {# vars - different format for pre v1.5 (yaml vs list) #}
            {% if invocation_args_dict.vars is string %}
                {# BigQuery does not handle the yaml-string from "--vars" well, when passed to "parse_json". Workaround is to parse the string, and then "tojson" will properly format the dict as a json-object. #}
                {% set parsed_inv_args_vars = fromyaml(invocation_args_dict.vars) %}
                {% do invocation_args_dict.update({'vars': parsed_inv_args_vars}) %}
            {% endif %}
        {% endif %}

        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(invocation_args_dict) | replace("'", "\\'")) }}, {# invocation_args #}

        {% set metadata_env = {} %}
        {% for key, value in dbt_metadata_envs.items() %}
            {% do metadata_env.update({key: value}) %}
        {% endfor %}
        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(metadata_env) | replace('\\', '\\\\')) }} {# dbt_custom_envs #}

        )
    {% endset %}
    {{ invocation_values }}

{% endmacro -%}

{% macro postgres__get_invocations_dml_sql() -%}
    {% set invocation_values %}
        (
            '{{ invocation_id }}', {# command_invocation_id #}
            '{{ dbt_version }}', {# dbt_version #}
            '{{ project_name }}', {# project_name #}
            '{{ run_started_at }}', {# run_started_at #}
            '{{ flags.WHICH }}', {# dbt_command #}
            {{ flags.FULL_REFRESH }}, {# full_refresh_flag #}
            '{{ target.profile_name }}', {# target_profile_name #}
            '{{ target.name }}', {# target_name #}
            '{{ target.schema }}', {# target_schema #}
            {{ target.threads }}, {# target_threads #}

            '{{ env_var("DBT_CLOUD_PROJECT_ID", "") }}', {# dbt_cloud_project_id #}
            '{{ env_var("DBT_CLOUD_JOB_ID", "") }}', {# dbt_cloud_job_id #}
            '{{ env_var("DBT_CLOUD_RUN_ID", "") }}', {# dbt_cloud_run_id #}
            '{{ env_var("DBT_CLOUD_RUN_REASON_CATEGORY", "") }}', {# dbt_cloud_run_reason_category #}
            $${{ env_var('DBT_CLOUD_RUN_REASON', '') }}$$, {# dbt_cloud_run_reason #}

            {% if var('env_vars', none) %}
                {% set env_vars_dict = {} %}
                {% for env_variable in var('env_vars') %}
                    {% do env_vars_dict.update({env_variable: (env_var(env_variable, ''))}) %}
                {% endfor %}
                $${{ tojson(env_vars_dict) }}$$, {# env_vars #}
            {% else %}
                null, {# env_vars #}
            {% endif %}

            {% if var('dbt_vars', none) %}
                {% set dbt_vars_dict = {} %}
                {% for dbt_var in var('dbt_vars') %}
                    {% do dbt_vars_dict.update({dbt_var: (var(dbt_var, ''))}) %}
                {% endfor %}
                $${{ tojson(dbt_vars_dict) }}$$, {# dbt_vars #}
            {% else %}
                null, {# dbt_vars #}
            {% endif %}

            {% if invocation_args_dict.vars %}
                {# vars - different format for pre v1.5 (yaml vs list) #}
                {% if invocation_args_dict.vars is string %}
                    {# BigQuery does not handle the yaml-string from "--vars" well, when passed to "parse_json". Workaround is to parse the string, and then "tojson" will properly format the dict as a json-object. #}
                    {% set parsed_inv_args_vars = fromyaml(invocation_args_dict.vars) %}
                    {% do invocation_args_dict.update({'vars': parsed_inv_args_vars}) %}
                {% endif %}
            {% endif %}

            $${{ tojson(invocation_args_dict) }}$$, {# invocation_args #}

            {% set metadata_env = {} %}
            {% for key, value in dbt_metadata_envs.items() %}
                {% do metadata_env.update({key: value}) %}
            {% endfor %}
            $${{ tojson(metadata_env) }}$$ {# dbt_custom_envs #}
        )
    {% endset %}
    {{ invocation_values }}

{% endmacro -%}


{% macro sqlserver__get_invocations_dml_sql() -%}
    {% set invocation_values %}
    select
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "10",
        nullif("11", ''),
        nullif("12", ''),
        nullif("13", ''),
        nullif("14", ''),
        nullif("15", ''),
        "16",
        "17",
        "18",
        "19"
    from (values
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

        '{{ env_var('DBT_CLOUD_PROJECT_ID', '') }}', {# dbt_cloud_project_id #}
        '{{ env_var('DBT_CLOUD_JOB_ID', '') }}', {# dbt_cloud_job_id #}
        '{{ env_var('DBT_CLOUD_RUN_ID', '') }}', {# dbt_cloud_run_id #}
        '{{ env_var('DBT_CLOUD_RUN_REASON_CATEGORY', '') }}', {# dbt_cloud_run_reason_category #}
        '{{ env_var('DBT_CLOUD_RUN_REASON', '') | replace("'","''") }}', {# dbt_cloud_run_reason #}
        {% if var('env_vars', none) %}
            {% set env_vars_dict = {} %}
            {% for env_variable in var('env_vars') %}
                {% do env_vars_dict.update({env_variable: (env_var(env_variable, '') | replace("'", "''"))}) %}
            {% endfor %}
            '{{ tojson(env_vars_dict) }}', {# env_vars #}
        {% else %}
            null, {# env_vars #}
        {% endif %}
        {% if var('dbt_vars', none) %}
            {% set dbt_vars_dict = {} %}
            {% for dbt_var in var('dbt_vars') %}
                {% do dbt_vars_dict.update({dbt_var: (var(dbt_var, '') | replace("'", "''"))}) %}
            {% endfor %}
            '{{ tojson(dbt_vars_dict) }}', {# dbt_vars #}
        {% else %}
            null, {# dbt_vars #}
        {% endif %}
        '{{ tojson(invocation_args_dict)  | replace("'", "''") }}', {# invocation_args #}

        {% set metadata_env = {} %}
        {% for key, value in dbt_metadata_envs.items() %}
            {% do metadata_env.update({key: (value | replace("'", "''"))}) %}
        {% endfor %}
        '{{ tojson(metadata_env) }}' {# dbt_custom_envs #}

    )

        ) v ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19")

    {% endset %}
    {{ invocation_values }}

{% endmacro -%}

