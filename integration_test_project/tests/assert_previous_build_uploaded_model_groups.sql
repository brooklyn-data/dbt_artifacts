/*
    Checks owner_group in the models dataset for the most recent earlier
    `dbt build`: every model's uploaded owner_group must equal its `group`
    config in the project graph, and be null for models with no group.
    Returns one row per model that doesn't match.

    The expected values come from the graph at compile time. On a fresh
    schema there is no earlier build and the test passes without checking.
*/

{%- set expected = [] %}
{%- if execute %}
    {%- for node in graph.nodes.values() | selectattr('resource_type', 'equalto', 'model') %}
        {%- do expected.append({'node_id': node.unique_id, 'owner_group': node.group}) %}
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
    select
        models.node_id
        , models.owner_group
    from {{ ref('dbt_artifacts', 'models') }} as models
    inner join last_invocation
        on models.command_invocation_id = last_invocation.command_invocation_id
)

, expected as (
    {%- for row in expected %}
    select
        '{{ row.node_id }}' as node_id
        , {{ "'" ~ row.owner_group ~ "'" if row.owner_group else "cast(null as " ~ dbt.type_string() ~ ")" }} as owner_group
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
    {%- if expected | length == 0 %}
    select cast(null as {{ dbt.type_string() }}) as node_id, cast(null as {{ dbt.type_string() }}) as owner_group
    {%- endif %}
)

select
    uploaded.node_id
    , uploaded.owner_group as uploaded_owner_group
    , expected.owner_group as expected_owner_group
from uploaded
inner join expected
    on uploaded.node_id = expected.node_id
where
    coalesce(uploaded.owner_group, '') != coalesce(expected.owner_group, '')
