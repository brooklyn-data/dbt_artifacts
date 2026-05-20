with
    base as (select * from {{ ref("stg_dbt__sources") }}),

    sources as (

        select
            source_execution_id,
            command_invocation_id,
            node_id,
            run_started_at,
            {% if target.type == "sqlserver" or target.type == "synapse" or target.type == "fabric" %} "database"
            {% else %} database
            {% endif %},
            {% if target.type == "sqlserver" or target.type == "synapse" or target.type == "fabric" %} "schema"
            {% else %} schema
            {% endif %},
            source_name,
            loader,
            name,
            identifier,
            loaded_at_field,
            freshness
        from base

    )

select *
from sources

