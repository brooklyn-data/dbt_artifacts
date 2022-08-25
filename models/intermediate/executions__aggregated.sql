with invocations as (

    select
        command_invocation_id
    
    from
        {{ ref('stg_dbt__invocations') }}

    where
        1 = 1
    
    {% if target.name == 'reddev' %}
        and run_started_at > dateadd('day', -10, current_date)
    
    {% elif is_incremental() %}
        and run_started_at > (select max(run_started_at) from {{ this }})
    
    {% endif %}

),

model_executions as (

    select
        models.command_invocation_id
      , count(distinct models.node_id) as models
      , sum(models.compile_execution_time) as compile_execution_time
      , sum(models.query_execution_time) as query_execution_time
      , sum(models.execution_time) as execution_time
      , max(models.query_completed_at) as last_query_completed_at

    from
        {{ ref('stg_dbt__model_executions') }} as models
    inner join
        invocations
        on models.command_invocation_id = invocations.command_invocation_id


    group by 1

),

seed_executions as (

    select
        seeds.command_invocation_id
      , count(distinct seeds.node_id) as seeds
      , sum(seeds.compile_execution_time) as compile_execution_time
      , sum(seeds.query_execution_time) as query_execution_time
      , sum(seeds.execution_time) as execution_time
      , max(seeds.query_completed_at) as last_query_completed_at

    from {{ ref('stg_dbt__seed_executions') }} as seeds
    inner join
        invocations
        on seeds.command_invocation_id = invocations.command_invocation_id

    group by 1

),

snapshot_executions as (

    select
        snapshots.command_invocation_id
      , count(distinct snapshots.node_id) as snapshots
      , sum(snapshots.compile_execution_time) as compile_execution_time
      , sum(snapshots.query_execution_time) as query_execution_time
      , sum(snapshots.execution_time) as execution_time
      , max(snapshots.query_completed_at) as last_query_completed_at

    from {{ ref('stg_dbt__snapshot_executions') }} as snapshots
    inner join
        invocations
        on snapshots.command_invocation_id = invocations.command_invocation_id

    group by 1

),

test_executions as (

    select
        tests.command_invocation_id
      , count(distinct tests.node_id) as tests
      , sum(tests.compile_execution_time) as compile_execution_time
      , sum(tests.query_execution_time) as query_execution_time
      , sum(tests.execution_time) as execution_time
      , max(tests.query_completed_at) as last_query_completed_at

    from {{ ref('stg_dbt__seed_executions') }} as tests
    inner join
        invocations
        on tests.command_invocation_id = invocations.command_invocation_id

    group by 1

),

last_query_union as (

    select command_invocation_id, last_query_completed_at from model_executions
    union all
    select command_invocation_id, last_query_completed_at from test_executions
    union all
    select command_invocation_id, last_query_completed_at from snapshot_executions
    union all
    select command_invocation_id, last_query_completed_at from model_executions

),

last_query_at as (

    select
        command_invocation_id
      , max(last_query_completed_at) as run_ended_at

    from last_query_union

    group by 1

),

final as (

    select
        invocations.command_invocation_id
      , last_query_at.run_ended_at
      , model_executions.models
      , test_executions.tests
      , snapshot_executions.snapshots
      , seed_executions.seeds
      , model_executions.compile_execution_time as compile_execution_time_models
      , model_executions.query_execution_time as query_execution_time_models
      , model_executions.execution_time as execution_time_models
      , test_executions.compile_execution_time as compile_execution_time_tests
      , test_executions.query_execution_time as query_execution_time_tests
      , test_executions.execution_time as execution_time_tests
      , snapshot_executions.compile_execution_time as compile_execution_time_snapshots
      , snapshot_executions.query_execution_time as query_execution_time_snapshots
      , snapshot_executions.execution_time as execution_time_snapshots
      , seed_executions.compile_execution_time as compile_execution_time_seeds
      , seed_executions.query_execution_time as query_execution_time_seeds
      , seed_executions.execution_time as execution_time_seeds
      , model_executions.compile_execution_time +
        test_executions.compile_execution_time +
        snapshot_executions.compile_execution_time +
        seed_executions.compile_execution_time as compile_execution_time
      , model_executions.query_execution_time +
        test_executions.query_execution_time +
        snapshot_executions.query_execution_time +
        seed_executions.query_execution_time as query_execution_time
      , model_executions.execution_time +
        test_executions.execution_time +
        snapshot_executions.execution_time +
        seed_executions.execution_time as execution_time

    from invocations
    left join last_query_at
        on invocations.command_invocation_id = last_query_at.command_invocation_id
    left join model_executions
        on invocations.command_invocation_id = model_executions.command_invocation_id
    left join test_executions
        on invocations.command_invocation_id = test_executions.command_invocation_id
    left join snapshot_executions
        on invocations.command_invocation_id = snapshot_executions.command_invocation_id
    left join seed_executions
        on invocations.command_invocation_id = seed_executions.command_invocation_id        

)

select * from final