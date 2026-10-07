{{ config(enabled = target.type in ["postgres", "redshift"]) }}
-- dim_dbt__current_relations must hold at most one row per (node_id,
-- target_name) and never a null relation coordinate: a consumer patches a
-- manifest with these values, so a duplicate silently picks a winner and a
-- null produces an unusable relation name. Returns rows (fails) on either
-- condition.
with duplicates as (
    select node_id
    from {{ ref("dim_dbt__current_relations") }}
    group by node_id, target_name
    having count(*) > 1
),

nulls as (
    select node_id
    from {{ ref("dim_dbt__current_relations") }}
    where database is null
        or schema is null
        or alias is null
        or resource_type is null
)

select node_id from duplicates
union all
select node_id from nulls
