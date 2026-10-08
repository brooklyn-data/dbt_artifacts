{{ config(enabled = target.type == "postgres") }}

{% if target.type == "postgres" %}
{% set compile_stage = {"name": "compile", "started_at": "2026-01-01 00:00:01", "completed_at": "2026-01-01 00:00:02"} %}
{% set execute_stage = {"name": "execute", "started_at": "2026-01-01 00:00:03", "completed_at": "2026-01-01 00:00:04"} %}
{% set cases = [
    ("complete", [compile_stage, execute_stage], "2026-01-01 00:00:01", "2026-01-01 00:00:04"),
    ("compile_only", [compile_stage], "2026-01-01 00:00:01", none),
    ("execute_only", [execute_stage], none, "2026-01-01 00:00:04"),
    ("empty", [], none, none),
    ("unrelated", [{"name": "prepare", "started_at": "2026-01-01 00:00:01", "completed_at": "2026-01-01 00:00:04"}], none, none),
    ("reversed", [execute_stage, compile_stage], "2026-01-01 00:00:01", "2026-01-01 00:00:04")
] %}
{% set results = [] %}
{% for name, timing, expected_compile, expected_execute in cases %}
    {% do results.append({
        "node": {
            "unique_id": name,
            "name": name,
            "alias": name,
            "schema": "timing_regression",
            "config": {"full_refresh": false, "materialized": "snapshot"}
        },
        "timing": timing,
        "thread_id": "Thread-1",
        "status": "success",
        "execution_time": 3.5,
        "failures": 0,
        "message": "timing regression",
        "adapter_response": {"rows_affected": 7}
    }) %}
{% endfor %}

with
    test_executions (
        command_invocation_id, node_id, run_started_at, was_full_refresh
        , thread_id, status, compile_started_at, query_completed_at
        , total_node_runtime, rows_affected, failures, message, adapter_response
    ) as (

        values {{ dbt_artifacts.upload_test_executions(results) }}

    )

    , snapshot_executions (
        command_invocation_id, node_id, run_started_at, was_full_refresh
        , thread_id, status, compile_started_at, query_completed_at
        , total_node_runtime, rows_affected, materialization, schema, name, alias
        , message, adapter_response
    ) as (

        values {{ dbt_artifacts.upload_snapshot_executions(results) }}

    )

    , actual as (

        select
            'test' as dataset
            , node_id
            , compile_started_at
            , query_completed_at
            , total_node_runtime
            , message
            , adapter_response
        from test_executions
        where failures = 0

        union all

        select
            'snapshot' as dataset
            , node_id
            , compile_started_at
            , query_completed_at
            , total_node_runtime
            , message
            , adapter_response
        from snapshot_executions
        where materialization = 'snapshot'
            and schema = 'timing_regression'
            and name = node_id
            and alias = node_id

    )

    , expected (node_id, compile_started_at, query_completed_at) as (

        values
        {% for name, timing, expected_compile, expected_execute in cases %}
            (
                '{{ name }}'
                , {% if expected_compile is none %}null{% else %}'{{ expected_compile }}'{% endif %}
                , {% if expected_execute is none %}null{% else %}'{{ expected_execute }}'{% endif %}
            ){% if not loop.last %},{% endif %}
        {% endfor %}

    )

    , datasets (dataset) as (

        values ('test'), ('snapshot')

    )

    , expected_executions as (

        select datasets.dataset, expected.*
        from expected
        cross join datasets

    )

select
    expected_executions.dataset
    , expected_executions.node_id
from expected_executions
full outer join actual
    on expected_executions.dataset = actual.dataset
    and expected_executions.node_id = actual.node_id
where actual.node_id is null
    or expected_executions.node_id is null
    or actual.compile_started_at is distinct from expected_executions.compile_started_at
    or actual.query_completed_at is distinct from expected_executions.query_completed_at
    or actual.total_node_runtime is distinct from 3.5
    or actual.message is distinct from 'timing regression'
    or actual.adapter_response::jsonb is distinct from '{"rows_affected": 7}'::jsonb
{% endif %}
