{#-
    get_smb_allowance()

    Resolves the monthly SMB allowance at compile time, returning a Python
    number or none. Resolution order (per specs/consumption/design.md):
      1. var('dbt_artifacts_smb_allowance')  -- explicit, wins
      2. plan default from var('dbt_artifacts_billing_plan')
         (developer: 3000, starter: 15000, enterprise: 100000)
      3. none  -- forecast projections still populate; breach columns stay null

    Plan allowances are published defaults that WILL drift; they are overridable
    and documented here in one place. Returns none for an unknown plan name.
-#}

{% macro get_smb_allowance() %}
    {%- set explicit = var("dbt_artifacts_smb_allowance", none) -%}
    {%- if explicit is not none -%}
        {{ return(explicit) }}
    {%- endif -%}

    {%- set plan = var("dbt_artifacts_billing_plan", none) -%}
    {%- set plan_allowances = {"developer": 3000, "starter": 15000, "enterprise": 100000} -%}
    {%- if plan is not none and plan in plan_allowances -%}
        {{ return(plan_allowances[plan]) }}
    {%- endif -%}

    {{ return(none) }}
{% endmacro %}
