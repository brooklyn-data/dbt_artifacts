{% macro upload_dbt_artifacts(table) %}
{% set filename %}
    {%- if table == 'manifests' -%}
        target/manifest.json
    {%- elif table == 'run_results' or table =='test_run_results' -%}
        target/run_results.json
    {%- else -%}
        {{ exceptions.raise_compiler_error("Invalid tablename passed. Got: " ~ table ~ " must be one of [manifests, run_results]") }}
    {%- endif -%}
{% endset %}
{% set put_query %}
    PUT file://{{ filename }} @{{ database }}.DBT.DBT_LOAD auto_compress=true;
{% endset %}
{% set copy_query %}
    BEGIN;
    COPY INTO {{ database }}.dbt.{{ table | upper }} FROM
        @{{ database }}.DBT.DBT_LOAD
        file_format=(type='JSON')
        on_error='skip_file';
    COMMIT;
{% endset %}
{% set remove_query %}
    REMOVE @{{ database }}.DBT.DBT_LOAD pattern='.*.json.gz';
{% endset %}
{% do log("Clearing files from Stage: " ~ remove_query, info=True) %}
{% do run_query(remove_query) %}
{% do log("Uploading file to Stage: " ~ put_query, info=True) %}
{% do run_query(put_query) %}
{% do log("Copying artifact from Stage: " ~ copy_query, info=True) %}
{% do run_query(copy_query) %}
{% do log("Removing artifact from Stage: " ~ remove_query, info=True) %}
{% do run_query(remove_query) %}
{% endmacro %}