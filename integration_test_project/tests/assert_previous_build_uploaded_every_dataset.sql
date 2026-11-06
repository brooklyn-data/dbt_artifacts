/*
    The on-run-end hook must write rows for every dataset. Tests run before the
    hook, so this checks the most recent earlier `dbt build` invocation already
    in the invocations table, and returns one row per dataset that got no rows
    for it.

    On a fresh schema (the first build) there is no earlier invocation and the
    test passes without checking anything. It becomes a real check from the
    second build onward, which is why the DuckDB tox envs build twice.

    Some flows warm up with `dbt build --exclude-resource-type test` (the
    Snowflake tox envs, Core and Fusion), so that earlier build has
    no test executions. They pass
    artifacts_test_previous_build_excluded_tests: true on the following build,
    and test_executions is then not required.
*/

with last_build as (
    select max(run_started_at) as run_started_at
    from {{ ref('dbt_artifacts', 'invocations') }}
    where dbt_command = 'build'
)

, last_invocation as (
    select invocations.command_invocation_id
    from {{ ref('dbt_artifacts', 'invocations') }} as invocations
    inner join last_build
        on invocations.run_started_at = last_build.run_started_at
    where invocations.dbt_command = 'build'
)

{%- set datasets = [
    'models', 'model_executions', 'seeds', 'seed_executions', 'tests', 'test_executions',
    'snapshots', 'snapshot_executions', 'sources', 'exposures'
] %}
{%- if var('artifacts_test_previous_build_excluded_tests', false) %}
    {%- do datasets.remove('test_executions') %}
{%- endif %}

, uploaded as (
    {%- for dataset in datasets %}
    select
        '{{ dataset }}' as dataset
        , count(uploaded_rows.command_invocation_id) as row_count
    from last_invocation
    left join {{ ref('dbt_artifacts', dataset) }} as uploaded_rows
        on last_invocation.command_invocation_id = uploaded_rows.command_invocation_id
    {#- Grouping makes an empty last_invocation return no rows instead of a zero count. #}
    group by last_invocation.command_invocation_id
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
)

select dataset
from uploaded
where row_count = 0
