{#
    One row per (node_id, target_name) describing the relation that target
    last built successfully. Unlike dim_dbt__current_models, which scopes to
    the most recent graph and covers models only, this view answers "what
    does the warehouse actually hold right now, per target" across models,
    seeds and snapshots, which is what a deferral consumer needs.

    The grain is per target, not per node, because several targets (e.g. a
    prod and a staging environment) can write to the same artifacts tables.
    Ranking node_id alone would collapse to one target's success and silently
    drop any other target's latest relation. dbt_artifacts.export_state is
    the layer that collapses this back to one row per node when its own
    target_name argument isn't given.
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

    invocations as (

        select command_invocation_id, target_name
        from {{ ref("stg_dbt__invocations") }}

    ),

    {# target_name has to be known before ranking, not just attached to the
       winner afterwards: the ranking itself must be scoped per target, or a
       node whose latest success ran on a different target than the one
       requested later (in export_state) is dropped instead of falling back
       to its own latest success on the requested target. #}
    executions_with_target as (

        select executions.*, invocations.target_name
        from executions
        left join invocations
            on executions.command_invocation_id = invocations.command_invocation_id

    ),

    successes as (

        select
            *,
            row_number() over (
                partition by node_id, target_name
                order by
                    {# A success with a null completion time must rank last,
                       not first: NULLS FIRST is Postgres/Redshift's default
                       for DESC, which would let a completion-time-less
                       success win over a real one. The case expression is
                       portable to every adapter this package supports,
                       including SQL Server, which has no NULLS LAST clause. #}
                    case when query_completed_at is null then 1 else 0 end,
                    query_completed_at desc
            ) as success_idx
        from executions_with_target
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

    final as (

        select
            {{ dbt_artifacts.generate_surrogate_key(["latest_success.node_id", "latest_success.target_name"]) }}
                as current_relation_id,
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
            latest_success.target_name,
            case
                when latest_graph.node_id is not null then true else false
            end as in_latest_graph
        from latest_success
        inner join dimensions
            on latest_success.command_invocation_id = dimensions.command_invocation_id
            and latest_success.node_id = dimensions.node_id
        left join latest_graph on latest_success.node_id = latest_graph.node_id

    )

select *
from final
