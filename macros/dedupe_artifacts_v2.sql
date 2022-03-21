{% macro dedupe_dbt_artifacts_v2() %}

{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_results_nodes = source('dbt_artifacts', 'dbt_run_results_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_manifest_nodes') %}

{% for artifact_table, table_key in [
    (src_results, 'command_invocation_id'),
    (src_results_nodes, 'command_invocation_id, node_id'),
    (src_manifest_nodes, 'artifact_run_id, node_id')
] %}

    {% set dedupe_results_query %}

        -- NB: Using a non-temporary table allows the clone operation next.
        create table {{ artifact_table.database }}.{{ artifact_table.schema }}.dbt_temp_artifact_table as
            select * from {{ artifact_table }}
            qualify row_number() over (
                partition by {{ table_key }}
                -- NB: Snowflake requires an order by clause, although all rows will be the same within a partition.
                order by artifact_generated_at
            ) = 1;

        create or replace table {{ artifact_table }} clone {{ artifact_table.database }}.{{ artifact_table.schema }}.dbt_temp_artifact_table;

        drop table {{ artifact_table.database }}.{{ artifact_table.schema }}.dbt_temp_artifact_table;

    {% endset %}

    {% do log("Deduping " ~ artifact_table ~ " : " ~ dedupe_results_query, info=True) %}
    {% do run_query(dedupe_results_query) %}

{% endfor %}

{% do log("Done", info=True) %}

{% endmacro %}
