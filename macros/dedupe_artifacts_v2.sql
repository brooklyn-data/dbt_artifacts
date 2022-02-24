{% macro dedupe_dbt_artifacts_v2() %}

{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_results_nodes = source('dbt_artifacts', 'dbt_run_results_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_run_manifest_nodes') %}

{% for artifact_table in [src_results, src_results_nodes, src_manifest_nodes] %}

    {% set dedupe_results_query %}

        create temporary table if not exists dbt_temp_artifact_table as
            select distinct * from {{ artifact_table }};
        
        truncate {{ artifact_table }};

        insert into {{ artifact_table }} select * from dbt_temp_artifact_table;

        drop table dbt_temp_artifact_table;

    {% endset %}

    {% do log("Deduping " ~ artifact_table ~ " : " ~ dedupe_results_query, info=True) %}
    {% do run_query(dedupe_results_query) %}

{% endfor %}

{% do log("DONE!", info=True) %}

{% endmacro %}