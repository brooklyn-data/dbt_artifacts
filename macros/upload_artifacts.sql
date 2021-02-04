{% macro upload_dbt_artifacts() %}
{% for file in ['manifest', 'run_results'] %}
    {% set put_query %}
        put file://target/{{ file }}.json @{{ var("dbt_artifacts_database") }}.{{ var("dbt_artifacts_schema") }}.artifacts_load auto_compress=true;
    {% endset %}
    {% set copy_query %}
        begin;
        copy into {{ var("dbt_artifacts_database") }}.{{ var("dbt_artifacts_schema") }}.{{ var("dbt_artifacts_table") }} from
            (
                select
                $1 as data,
                $1:metadata:generated_at::timestamp_ntz as generated_at,
                metadata$filename as path,
                regexp_substr(metadata$filename, '([a-z_]+.json)$') as artifact_type
                from  @{{ var("dbt_artifacts_database") }}.{{ var("dbt_artifacts_schema") }}.artifacts_load
            )
            file_format=(type='JSON')
            on_error='skip_file';
        commit;
    {% endset %}
    {% set remove_query %}
        remove @{{ var("dbt_artifacts_database") }}.{{ var("dbt_artifacts_schema") }}.artifacts_load pattern='.*.json.gz';
    {% endset %}
    {% do log("Clearing files from Stage: " ~ remove_query, info=True) %}
    {% do run_query(remove_query) %}
    {% do log("Uploading " ~ file ~ " to Stage: " ~ put_query, info=True) %}
    {% do run_query(put_query) %}
    {% do log("Copying " ~ file ~ " from Stage: " ~ copy_query, info=True) %}
    {% do run_query(copy_query) %}
    {% do log("Removing " ~ file ~ " from Stage: " ~ remove_query, info=True) %}
    {% do run_query(remove_query) %}

{% endfor %}

{% endmacro %}

