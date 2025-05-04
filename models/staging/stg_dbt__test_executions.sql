with
    base as (

        select *
        from {{ ref('test_executions') }}

    )

    , enhanced as (

        select
            {{ dbt_artifacts.generate_surrogate_key(['command_invocation_id', 'node_id']) }} as test_execution_id
            , command_invocation_id
            , node_id
            , run_started_at
            , was_full_refresh
            ,
            {% if target.type == "clickhouse" %} {{ split_part("coalesce(thread_id, '')", "'-'", 2) }} as thread_id
            {% else %} {{ split_part("thread_id", "'-'", 2) }} as thread_id
            {% endif %}
            , status
            , compile_started_at
            , query_completed_at
            , total_node_runtime
            , rows_affected
            , failures
            , message
        from base

    )

select * from enhanced
