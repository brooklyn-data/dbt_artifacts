{% macro upload_dbt_artifacts(filenames, prefix='target/') %}

{% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}

{# All uploads are prefixed by the invocation_id in the stage to isolate parallel jobs from one another #}
{% set remove_query %}
    remove @{{ src_dbt_artifacts }} pattern='.*\/{{ invocation_id }}\/.*\.json.gz';
{% endset %}

{% do log("Clearing existing files from Stage: " ~ remove_query, info=True) %}
{% do run_query(remove_query) %}

{% for filename in filenames %}

    {% set file = filename ~ '.json' %}

    {% set put_query %}
        put file://{{ prefix }}{{ file }} @{{ src_dbt_artifacts }}/{{ invocation_id }} auto_compress=true;
    {% endset %}

    {% do log("Uploading " ~ file ~ " to Stage: " ~ put_query, info=True) %}
    {% do run_query(put_query) %}

    {% set copy_query %}

        -- Merge to avoid duplicates
        merge into {{ src_dbt_artifacts }} as old_data using (
            select
            $1 as data,
            $1:metadata:generated_at::timestamp_ntz as generated_at,
            metadata$filename as path,
            regexp_substr(metadata$filename, '([a-z_]+.json)') as artifact_type
            from  @{{ src_dbt_artifacts }}/{{ invocation_id }}
        ) as new_data
        on old_data.generated_at = new_data.generated_at
        -- NB: No clause for "when matched" - as matching rows should be skipped.
        when not matched then insert (
            data,
            generated_at,
            path,
            artifact_type
        ) values (
            new_data.data,
            new_data.generated_at,
            new_data.path,
            new_data.artifact_type
        )

    {% endset %}

    {% do log("Copying " ~ file ~ " from Stage: " ~ copy_query, info=True) %}
    {% do run_query(copy_query) %}

{% endfor %}

{% do log("Clearing new files from Stage: " ~ remove_query, info=True) %}
{% do run_query(remove_query) %}

{% endmacro %}
