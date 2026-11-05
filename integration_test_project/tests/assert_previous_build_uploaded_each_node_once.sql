/*
    The on-run-end hook uploads manifest datasets in chunks. This checks that
    the most recent earlier `dbt build` uploaded each node exactly once:
    every dataset must have as many rows, and as many distinct node_ids, as
    the project graph has nodes of that type. A chunk boundary that drops or
    repeats rows fails it. Returns one row per dataset that doesn't match.

    Like assert_previous_build_uploaded_every_dataset, it passes without
    checking on a fresh schema, and the DuckDB tox envs build twice so it
    checks real data. Their first build uses small batch sizes, so most
    datasets are split across several chunks.
*/

{%- set expected_counts = {} %}
{%- if execute %}
    {%- for dataset in ['models', 'seeds', 'snapshots', 'tests'] %}
        {%- do expected_counts.update({
            dataset: graph.nodes.values() | selectattr('resource_type', 'equalto', dataset[:-1]) | list | length
        }) %}
    {%- endfor %}
    {%- for dataset in ['sources', 'exposures'] %}
        {%- do expected_counts.update({dataset: graph.get(dataset).values() | list | length}) %}
    {%- endfor %}
{%- endif %}

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

, uploaded as (
    {%- for dataset in ['models', 'seeds', 'snapshots', 'tests', 'sources', 'exposures'] %}
    select
        '{{ dataset }}' as dataset
        , {{ expected_counts.get(dataset, 0) }} as expected_count
        , count(uploaded_rows.node_id) as row_count
        , count(distinct uploaded_rows.node_id) as distinct_node_count
    from last_invocation
    left join {{ ref('dbt_artifacts', dataset) }} as uploaded_rows
        on last_invocation.command_invocation_id = uploaded_rows.command_invocation_id
    {#- Grouping makes an empty last_invocation return no rows instead of zero counts. #}
    group by last_invocation.command_invocation_id
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
)

select
    dataset
    , expected_count
    , row_count
    , distinct_node_count
from uploaded
where
    row_count != expected_count
    or distinct_node_count != expected_count
