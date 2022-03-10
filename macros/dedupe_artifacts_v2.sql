{% macro dedupe_dbt_artifacts_v2() %}

{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_results_nodes = source('dbt_artifacts', 'dbt_run_results_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_run_manifest_nodes') %}

{% for artifact_table in [src_results, src_results_nodes, src_manifest_nodes] %}

    {% set dedupe_results_query %}

        create temporary table {{ artifact_table.database }}.{{ artifact_table.schema }}.dbt_temp_artifact_table as
            select * from {{ artifact_table }}
            qualify row_number() over (
                partition by artifact_run_id, artifact_generated_at
                -- NB: Snowflake requires an order by clause, although all rows will be the same within a partition.
                order by artifact_generated_at
            ) = 1;
        
        truncate {{ artifact_table }};

        insert into {{ artifact_table }} select * from {{ artifact_table.database }}.{{ artifact_table.schema }}.dbt_temp_artifact_table;

        drop table {{ artifact_table.database }}.{{ artifact_table.schema }}.dbt_temp_artifact_table;

    {% endset %}

    {% do log("Deduping " ~ artifact_table ~ " : " ~ dedupe_results_query, info=True) %}
    {% do run_query(dedupe_results_query) %}

{% endfor %}

{% do log("DONE!", info=True) %}

{% endmacro %}
