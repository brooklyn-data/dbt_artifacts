with
    base as (select * from {{ ref("snapshots") }}),

    enhanced as (

        select
            {{ dbt_artifacts.generate_surrogate_key(["command_invocation_id", "node_id"]) }}
            as snapshot_execution_id,
            command_invocation_id,
            node_id,
            run_started_at,
            {% if target.type in ["sqlserver", "fabric"] %} "database"
            {% else %} database
            {% endif %},
            {% if target.type in ["sqlserver", "fabric"] %} "schema"
            {% else %} schema
            {% endif %},
            name,
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
from enhanced

