{#-
    classify_invocation_billing()

    Returns a scalar-per-row SQL `case` expression that classifies each
    invocation as 'deployment' or 'development'. dbt bills only orchestrated
    deployment builds, so every consumption metric filters on this.

    Consumed inside the new consumption models' CTEs only -- it references the
    columns dbt_cloud_job_id, target_name and env_vars, which must be in scope
    (they are on stg_dbt__invocations). This macro does NOT modify any existing
    staging/source contract.

    Precedence (first match wins), per specs/consumption/design.md:
      1. dbt_cloud_job_id is not null                         -> deployment
      2. lower(target_name) in deployment_targets (lowered)   -> deployment
      3. optional: env var named by dbt_artifacts_deployment_env_var is
         present and truthy in env_vars                       -> deployment
      fallback                                                -> development

    Escape hatch: dbt_artifacts_count_all_invocations = true classes every
    invocation as deployment.

    Rule 3 needs adapter-specific JSON access, so it lives only in snowflake__
    (env_vars is stored via type_json() = OBJECT on Snowflake, accessed with
    the variant path env_vars:"NAME"). It is emitted only when the var is set,
    so the default path parses no JSON. default__ raises a clear compile error
    if rule 3 is requested on an unsupported adapter (fast-follow C-11).
-#}

{% macro classify_invocation_billing() %}
    {{ return(adapter.dispatch('classify_invocation_billing', 'dbt_artifacts')()) }}
{% endmacro %}


{#- Shared predicate for rule 2: lower(target_name) in the (lowered) deployment
    target list. Emits `false` for an empty list so `in ()` is never produced. -#}
{% macro _billing_deployment_targets_predicate() %}
    {%- set targets = var('dbt_artifacts_deployment_targets', ['prod', 'production', 'ci']) -%}
    {%- if targets | length == 0 -%}
        false
    {%- else -%}
        lower(target_name) in (
            {%- for t in targets -%}
                '{{ t | lower }}'{% if not loop.last %}, {% endif %}
            {%- endfor -%}
        )
    {%- endif -%}
{% endmacro %}


{% macro default__classify_invocation_billing() %}
    {%- if var('dbt_artifacts_count_all_invocations', false) -%}
        cast('deployment' as {{ dbt.type_string() }})
    {%- else -%}
        {#- Raise only at run time (execute == true), never during parse, so a
            non-Snowflake consumer's `dbt parse` is unaffected even with this var
            set. The consumption models that call this are Snowflake-gated anyway. -#}
        {%- if var('dbt_artifacts_deployment_env_var', none) is not none and execute -%}
            {{ exceptions.raise_compiler_error(
                "dbt_artifacts_deployment_env_var (billing classification rule 3) requires adapter-specific JSON support and is only implemented for Snowflake in v1. Unset the var or run on Snowflake."
            ) }}
        {%- endif -%}
        case
            when dbt_cloud_job_id is not null then 'deployment'
            when {{ dbt_artifacts._billing_deployment_targets_predicate() }} then 'deployment'
            else 'development'
        end
    {%- endif -%}
{% endmacro %}


{% macro snowflake__classify_invocation_billing() %}
    {%- if var('dbt_artifacts_count_all_invocations', false) -%}
        cast('deployment' as {{ dbt.type_string() }})
    {%- else -%}
        {%- set env_var_name = var('dbt_artifacts_deployment_env_var', none) -%}
        case
            when dbt_cloud_job_id is not null then 'deployment'
            when {{ dbt_artifacts._billing_deployment_targets_predicate() }} then 'deployment'
            {%- if env_var_name is not none %}
            when coalesce(env_vars:"{{ env_var_name }}"::string, '') not in ('', 'false', 'False', '0')
                then 'deployment'
            {%- endif %}
            else 'development'
        end
    {%- endif -%}
{% endmacro %}
