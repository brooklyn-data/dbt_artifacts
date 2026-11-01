{{ config(enabled = target.type == "snowflake") }}
-- consumption_daily must have at least one 'smb' row with quantity > 0
-- after the harness's deployment-classed runs. Fails (returns a row) if none.
select count(*) as smb_rows_with_quantity
from {{ ref("fct_dbt__consumption_daily") }}
where meter = 'smb'
    and quantity > 0
having count(*) = 0
