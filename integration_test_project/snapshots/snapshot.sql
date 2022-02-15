{% snapshot my_snapshot %}
{{
    config(
        strategy='check',
        unique_key='id',
        target_schema='snapshot',
        check_cols=['id', 'fruit'],
    )
}}

select * from {{ ref('non_incremental') }}

{% endsnapshot %}
