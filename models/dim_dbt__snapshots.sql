with
    base as (select * from {{ ref("stg_dbt__snapshots") }}),

    snapshots as (

        select
            snapshot_execution_id,
            command_invocation_id,
            node_id,
            run_started_at,
            name,
            {% if target.type == "sqlserver" %} "database"
            {% else %} database
            {% endif %},
            {% if target.type == "sqlserver" %} "schema"
            {% else %} schema
            {% endif %},
            depends_on_nodes,
            package_name,
            path,
            checksum,
            strategy,
            meta,
            alias
        from base

    )

select *
from snapshots

