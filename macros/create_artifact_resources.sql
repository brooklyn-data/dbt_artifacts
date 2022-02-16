{% macro create_artifact_resources() %}

{% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}
{% set artifact_stage = var('dbt_artifacts_stage', 'dbt_artifacts_stage') %}

{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_result_nodes = source('dbt_artifacts', 'dbt_run_result_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_run_manifest_nodes') %}

{{ create_schema(src_dbt_artifacts) }}

{% set create_stage_query %}
create stage if not exists {{ src_dbt_artifacts }}
file_format = (type = json);
{% endset %}

{% set create_new_stage_query %}
create stage if not exists {{ artifact_stage }}
file_format = ( type =  json );
{% endset %}

{% set create_table_query %}
create table if not exists {{ src_dbt_artifacts }} (
    data variant,
    generated_at timestamp,
    path string,
    artifact_type string
);
{% endset %}

{% set create_results_query %}
create table if not exists {{ src_results }} (
    command_invocation_id string,
    dbt_cloud_run_id int,
    artifact_run_id string,
    artifact_generated_at timestamp_ntz,
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

{% set create_result_nodes_table_query %}
create table if not exists {{ src_result_nodes }} (
    command_invocation_id string,
    dbt_cloud_run_id int,
    artifact_run_id string,
    artifact_generated_at timestamp_ntz,
    execution_command string,
    was_full_refresh boolean,
    node_id string,
    thread_id integer,
    status string,
    message string,
    compile_started_at timestamp_ntz,
    query_completed_at timestamp_ntz,
    total_node_runtime float,
    rows_affected int,
    result_json variant
);
{% endset %}

{% set create_manifest_nodes_table_query %}
create table if not exists {{ src_manifest_nodes }} (
    command_invocation_id string,
    dbt_cloud_run_id int,
    artifact_run_id string,
    artifact_generated_at timestamp_ntz,
    node_id string,
    resource_type string,
    node_database string,
    node_schema string,
    name string,
    depends_on_nodes array,
    depends_on_sources array,
    exposure_type string,
    exposure_owner string,
    exposure_maturity string,
    source_name string,
    package_name string,
    relation_name string,
    node_path string,
    checksum string,
    materialization string,
    node_json variant
);
{% endset %}

{% do log("Creating Old Stage: " ~ create_stage_query, info=True) %}
{% do run_query(create_stage_query) %}

{% do log("Creating New Stage: " ~ create_new_stage_query, info=True) %}
{% do run_query(create_new_stage_query) %}

{% do log("Creating Table: " ~ create_table_query, info=True) %}
{% do run_query(create_table_query) %}

{% do log("Creating Results Table: " ~ create_results_query, info=True) %}
{% do run_query(create_results_query) %}

{% do log("Creating Result Nodes Table: " ~ create_result_nodes_table_query, info=True) %}
{% do run_query(create_result_nodes_table_query) %}

{% do log("Creating Manifest Nodes Table: " ~ create_manifest_nodes_table_query, info=True) %}
{% do run_query(create_manifest_nodes_table_query) %}

{% endmacro %}
