/*
    Checks compiled_sql and audit_table_name in test_executions for the most
    recent earlier `dbt build`. Returns one row per test execution where:
    - compiled_sql is null for a test that ran (passed, warned or failed);
    - long_compiled_test's compiled_sql is shorter than its 9,000-character
      comment, so the value was cut off;
    - audit_table_name is set for a test that doesn't store failures, or null
      for one that does.

    Expected values come from the graph at compile time. On a fresh schema
    there is no earlier build and the test passes without checking; the DuckDB
    tox envs build twice so it checks real data.
*/

{%- set expected = [] %}
{%- if execute %}
    {%- for node in graph.nodes.values() | selectattr('resource_type', 'equalto', 'test') %}
        {%- set store_failures = node.config.store_failures if node.config.store_failures is not none else flags.STORE_FAILURES %}
        {%- do expected.append({
            'node_id': node.unique_id,
            'stores_failures': 1 if store_failures else 0,
            'min_compiled_length': 9000 if node.name == 'long_compiled_test' else 1
        }) %}
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
        test_executions.node_id
        , test_executions.status
        , coalesce({{ dbt.length('test_executions.compiled_sql') }}, 0) as compiled_length
        , case when test_executions.audit_table_name is null then 0 else 1 end as has_audit_table_name
    from {{ ref('dbt_artifacts', 'test_executions') }} as test_executions
    inner join last_invocation
        on test_executions.command_invocation_id = last_invocation.command_invocation_id
)

, expected as (
    {%- for row in expected %}
    select
        '{{ row.node_id }}' as node_id
        , {{ row.stores_failures }} as stores_failures
        , {{ row.min_compiled_length }} as min_compiled_length
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
    {%- if expected | length == 0 %}
    select cast(null as {{ dbt.type_string() }}) as node_id, 0 as stores_failures, 0 as min_compiled_length
    {%- endif %}
)

select
    uploaded.node_id
    , uploaded.status
    , uploaded.compiled_length
    , expected.min_compiled_length
    , uploaded.has_audit_table_name
    , expected.stores_failures
from uploaded
inner join expected
    on uploaded.node_id = expected.node_id
where
    (uploaded.status in ('pass', 'warn', 'fail') and uploaded.compiled_length < expected.min_compiled_length)
    or uploaded.has_audit_table_name != expected.stores_failures
