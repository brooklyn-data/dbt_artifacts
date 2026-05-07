{{
    config(
        materialized='incremental',
        unique_key='id',
        meta={"meta_field": "description with an ' apostrophe"},
    )
}}

-- {{ source('dummy_source', '"GROUP"') }}

select

{% if is_incremental() %}

    1 as id,
    cast('banana' as {{ dbt.type_string() }}) as fruit

{% else %}

    2 as id,
    cast('apple' as {{ dbt.type_string() }}) as fruit

{% endif %}
