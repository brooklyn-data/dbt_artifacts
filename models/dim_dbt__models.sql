with
    base as (select * from {{ ref("stg_dbt__models") }}),

    models as (

        select
            model_execution_id,
            command_invocation_id,
            node_id,
            run_started_at,
            name,
            {% if target.type == "sqlserver" or target.type == "synapse" or target.type == "fabric" %} "database"
            {% else %} database
            {% endif %},
            {% if target.type == "sqlserver" or target.type == "synapse" or target.type == "fabric" %} "schema"
            {% else %} schema
            {% endif %},
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
from models

