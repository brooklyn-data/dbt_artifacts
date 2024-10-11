-- Exclude this from Spark tests as it complains:
-- Snapshot functionality requires file_format be set to 'delta' or 'hudi'
-- It's not possible to dynamically change the file_format depending on target
{% snapshot my_snapshot %}
{{
    config(
        strategy='check',
        unique_key='id',
        target_schema=target.schema,
        check_cols=['id', 'fruit'],
        tags="snapshot"
    )
}}

select * from {{ ref('non_incremental') }}

{% endsnapshot %}
