{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

-- {{ source('dummy_source', '"GROUP"') }}

select

{% if is_incremental() %}

    1 as id,
    'banana' as fruit

{% else %}

    2 as id,
    'apple' as fruit

{% endif %}
