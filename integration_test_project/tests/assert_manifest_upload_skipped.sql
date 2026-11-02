/*
    Checks that dbt_artifacts_upload_manifest = false skips the manifest
    datasets but still uploads invocations and executions. Disabled unless
    dbt_artifacts_test_expect_manifest_skipped is true: the DuckDB tox envs
    run a model with the flag off, then run only this test, so the most
    recent invocation in the table is that run.

    Returns one row per dataset that doesn't match: a manifest dataset with
    rows for that invocation, or model_executions with none.
*/

{{ config(enabled = var('dbt_artifacts_test_expect_manifest_skipped', false)) }}

with last_invocation as (
    select command_invocation_id
    from {{ ref('dbt_artifacts', 'invocations') }}
    where run_started_at = (
        select max(run_started_at)
        from {{ ref('dbt_artifacts', 'invocations') }}
    )
)

{%- set manifest_datasets = ['models', 'seeds', 'snapshots', 'sources', 'tests', 'exposures'] %}
{%- set datasets = manifest_datasets + ['model_executions'] %}

, uploaded as (
    {%- for dataset in datasets %}
    select
        '{{ dataset }}' as dataset
        , {{ 1 if dataset in manifest_datasets else 0 }} as is_manifest_dataset
        , count(uploaded_rows.command_invocation_id) as row_count
    from last_invocation
    left join {{ ref('dbt_artifacts', dataset) }} as uploaded_rows
        on last_invocation.command_invocation_id = uploaded_rows.command_invocation_id
    group by last_invocation.command_invocation_id
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
)

select
    dataset
    , row_count
from uploaded
where
    (is_manifest_dataset = 1 and row_count > 0)
    or (is_manifest_dataset = 0 and row_count = 0)
