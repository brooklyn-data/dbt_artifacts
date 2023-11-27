{% if target.name == 'athena' %}
{{
    config(
        materialized='incremental',
        unique_key='id',
        meta={"meta_field": "description with an ' apostrophe"},
        table_type='iceberg',
        file_format='parquet',
        incremental_strategy='merge'
    )
}}
{% else %}
{{
    config(
        materialized='incremental',
        unique_key='id',
        meta={"meta_field": "description with an ' apostrophe"},
    )
}}
{% endif %}
-- {{ source('dummy_source', '"GROUP"') }}

select

{% if is_incremental() %}

    1 as id,
    'banana' as fruit

{% else %}

    2 as id,
    'apple' as fruit

{% endif %}
