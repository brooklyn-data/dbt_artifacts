with
    base as (
        select * from {{ ref("models") }}
    )

    , enhanced as (

        select
            {{ dbt_artifacts.generate_surrogate_key(["command_invocation_id", "node_id"]) }}
            as model_execution_id,
            command_invocation_id,
            node_id,
            run_started_at,
            {% if target.type == "sqlserver" %} "database"
            {% else %} database
            {% endif %},
            {% if target.type == "sqlserver" %} "schema"
            {% else %} schema
            {% endif %},  -- noqa
            name,
            depends_on_nodes,
            package_name,
            path,
            checksum,
            materialization,
            tags,
            meta,
            alias
        from base

    )

select *
from enhanced

