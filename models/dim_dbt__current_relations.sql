{#
    One row per refable node describing the relation production last built
    successfully. Unlike dim_dbt__current_models, which scopes to the most
    recent graph and covers models only, this view answers "what does the
    warehouse actually hold right now" across models, seeds and snapshots,
    which is what a deferral consumer needs.
#}
with
    executions as (

        select
            command_invocation_id,
            node_id,
            'model' as resource_type,
            run_started_at,
            status,
            query_completed_at,
            materialization,
            {% if target.type == "sqlserver" %} "schema"
            {% else %} schema
            {% endif %},  -- noqa
            name,
            alias
        from {{ ref("stg_dbt__model_executions") }}

        union all

        select
            command_invocation_id,
            node_id,
            'seed' as resource_type,
            run_started_at,
            status,
            query_completed_at,
            materialization,
            {% if target.type == "sqlserver" %} "schema"
            {% else %} schema
            {% endif %},  -- noqa
            name,
            alias
        from {{ ref("stg_dbt__seed_executions") }}

        union all

        select
            command_invocation_id,
            node_id,
            'snapshot' as resource_type,
            run_started_at,
            status,
            query_completed_at,
            materialization,
            {% if target.type == "sqlserver" %} "schema"
            {% else %} schema
            {% endif %},  -- noqa
            name,
            alias
        from {{ ref("stg_dbt__snapshot_executions") }}

    ),

    successes as (

        select
            *,
            row_number() over (
                partition by node_id order by query_completed_at desc
            ) as success_idx
        from executions
        where status = 'success'

    ),

    latest_success as (select * from successes where success_idx = 1),

    dimensions as (

        select
            command_invocation_id,
            node_id,
            {% if target.type == "sqlserver" %} "database"
            {% else %} database
            {% endif %},  -- noqa
            package_name,
            checksum,
            run_started_at
        from {{ ref("stg_dbt__models") }}

        union all

        select
            command_invocation_id,
            node_id,
            {% if target.type == "sqlserver" %} "database"
            {% else %} database
            {% endif %},  -- noqa
            package_name,
            checksum,
            run_started_at
        from {{ ref("stg_dbt__seeds") }}

        union all

        select
            command_invocation_id,
            node_id,
            {% if target.type == "sqlserver" %} "database"
            {% else %} database
            {% endif %},  -- noqa
            package_name,
            checksum,
            run_started_at
        from {{ ref("stg_dbt__snapshots") }}

    ),

    latest_graph as (

        {# Nodes present in the most recent graph, whether or not they ran. #}
        select node_id
        from dimensions
        where run_started_at = (select max(d.run_started_at) from dimensions as d)

    ),

    invocations as (

        select command_invocation_id, target_name
        from {{ ref("stg_dbt__invocations") }}

    ),

    final as (

        select
            latest_success.node_id,
            latest_success.resource_type,
            latest_success.name,
            dimensions.package_name,
            dimensions.database,
            latest_success.schema,
            latest_success.alias,
            latest_success.materialization,
            dimensions.checksum,
            latest_success.query_completed_at as last_success_at,
            latest_success.command_invocation_id,
            latest_success.run_started_at,
            invocations.target_name,
            case
                when latest_graph.node_id is not null then true else false
            end as in_latest_graph
        from latest_success
        inner join dimensions
            on latest_success.command_invocation_id = dimensions.command_invocation_id
            and latest_success.node_id = dimensions.node_id
        left join invocations
            on latest_success.command_invocation_id = invocations.command_invocation_id
        left join latest_graph on latest_success.node_id = latest_graph.node_id

    )

select *
from final
