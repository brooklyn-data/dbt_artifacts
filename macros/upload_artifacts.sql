{% macro upload_dbt_artifacts() %}
{% for file in ['manifest', 'run_results'] %}

    {% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}

    {% set put_query %}
        put file://target/{{ file }}.json @{{ src_dbt_artifacts }} auto_compress=true;
    {% endset %}
    {% set copy_query %}
        begin;
        copy into {{ src_dbt_artifacts }} from
            (
                select
                $1 as data,
                $1:metadata:generated_at::timestamp_ntz as generated_at,
                metadata$filename as path,
                regexp_substr(metadata$filename, '([a-z_]+.json)$') as artifact_type
                from  @{{ src_dbt_artifacts }}
            )
            file_format=(type='JSON')
            on_error='skip_file';
        commit;
    {% endset %}
    {% set remove_query %}
        remove @{{ src_dbt_artifacts }} pattern='.*.json.gz';
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

