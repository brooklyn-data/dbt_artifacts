{{
    config(
        materialized = 'incremental',
        unique_key = 'test_execution_id'
    )
}}

with tests as (

    select distinct

        node_id,
        test_name,
        test_type,
        model_schema,
        case
            when model_path ilike '%bespoke_tests/%'
                then replace(model_path, 'bespoke_tests/', '')
            when model_path ilike '%schema_test/%'
                then replace(model_path, 'schema_test/', '')
            when model_path ilike 'data_test/%'
                then replace(model_path, 'data_test/', '')
            else model_path
        end as model_path

    from {{ ref('int_dbt_tests') }}

),

test_executions as (

    select * from {{ ref('int_dbt_test_executions') }}

),

test_executions_incremental as (

    select * from test_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
        where artifact_generated_at > (
            select max(artifact_generated_at)
            from {{ this }}
        )
    {% endif %}

),

test_executions_with_materialization as (

    select

        {{ dbt_utils.surrogate_key([
                'command_invocation_id',
                'tests.node_id',
                'tests.model_schema'])
            }} as test_id,

        test_executions_incremental.*,

        tests.test_name,
        tests.test_type,
        tests.model_schema,
        tests.model_path

    from test_executions_incremental
    left join tests
        on test_executions_incremental.node_id = tests.node_id

)

select * from test_executions_with_materialization