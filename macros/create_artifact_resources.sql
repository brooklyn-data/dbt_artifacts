{% macro create_artifact_resources() %}

{% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}
{% set artifact_stage = src_dbt_artifacts.database ~ "." ~ src_dbt_artifacts.schema ~ "." ~ var('dbt_artifacts_stage', 'dbt_artifacts_stage') %}

{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_results_nodes = source('dbt_artifacts', 'dbt_run_results_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_manifest_nodes') %}

{{ create_schema(src_dbt_artifacts) }}

{% set create_v1_stage_query %}
create stage if not exists {{ src_dbt_artifacts }}
file_format = (type = json);
{% endset %}

{% set create_v2_stage_query %}
create stage if not exists {{ artifact_stage }}
file_format = (type = json);
{% endset %}

{% set create_v1_table_query %}
create table if not exists {{ src_dbt_artifacts }} (
    data variant,
    generated_at timestamp,
    path string,
    artifact_type string
);
{% endset %}

{% set create_v2_results_query %}
create table if not exists {{ src_results }} (
    command_invocation_id string,
    dbt_cloud_run_id int,
    artifact_run_id string,
    artifact_generated_at timestamp_tz,
    dbt_version string,
    env variant,
    elapsed_time double,
    execution_command string,
    was_full_refresh boolean,
    selected_models variant,
    target string,
    metadata variant,
    args variant
);
{% endset %}

{% set create_v2_result_nodes_table_query %}
create table if not exists {{ src_results_nodes }} (
    command_invocation_id string,
    dbt_cloud_run_id int,
    artifact_run_id string,
    artifact_generated_at timestamp_tz,
    execution_command string,
    was_full_refresh boolean,
    node_id string,
    status string,
    compile_started_at timestamp_tz,
    query_completed_at timestamp_tz,
    total_node_runtime float,
    result_json variant
);
{% endset %}

{% set create_v2_manifest_nodes_table_query %}
create table if not exists {{ src_manifest_nodes }} (
    command_invocation_id string,
    dbt_cloud_run_id int,
    artifact_run_id string,
    artifact_generated_at timestamp_tz,
    node_id string,
    resource_type string,
    node_database string,
    node_schema string,
    name string,
    node_json variant
);
{% endset %}

{% do log("Creating V1 Stage: " ~ create_v1_stage_query, info=True) %}
{% do run_query(create_v1_stage_query) %}

{% do log("Creating V2 Stage: " ~ create_v2_stage_query, info=True) %}
{% do run_query(create_v2_stage_query) %}

{% do log("Creating V1 Table: " ~ create_v1_table_query, info=True) %}
{% do run_query(create_v1_table_query) %}

{% do log("Creating V2 Results Table: " ~ create_v2_results_query, info=True) %}
{% do run_query(create_v2_results_query) %}

{% do log("Creating V2 Result Nodes Table: " ~ create_v2_result_nodes_table_query, info=True) %}
{% do run_query(create_v2_result_nodes_table_query) %}

{% do log("Creating V2 Manifest Nodes Table: " ~ create_v2_manifest_nodes_table_query, info=True) %}
{% do run_query(create_v2_manifest_nodes_table_query) %}

{% endmacro %}
