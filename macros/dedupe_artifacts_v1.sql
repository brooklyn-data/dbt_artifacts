{% macro dedupe_dbt_artifacts_v1() %}

{% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}

{% set dedupe_results_query %}

    create temporary table {{ src_dbt_artifacts.database }}.{{ src_dbt_artifacts.schema }}.dbt_temp_artifact_table as
        select * from {{ src_dbt_artifacts }}
        qualify row_number() over (
            partition by generated_at
            -- NB: Snowflake requires an order by clause, although all rows will be the same within a partition.
            order by generated_at
        ) = 1;
    
    truncate {{ src_dbt_artifacts }};

    insert into {{ src_dbt_artifacts }} select * from {{ src_dbt_artifacts.database }}.{{ src_dbt_artifacts.schema }}.dbt_temp_artifact_table;

    drop table {{ src_dbt_artifacts.database }}.{{ src_dbt_artifacts.schema }}.dbt_temp_artifact_table;

{% endset %}

{% do log("Deduping " ~ src_dbt_artifacts ~ " : " ~ dedupe_results_query, info=True) %}
{% do run_query(dedupe_results_query) %}


{% do log("DONE!", info=True) %}

{% endmacro %}
