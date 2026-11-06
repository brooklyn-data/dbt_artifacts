/*
    Checks that a run with --sample uploads its invocation, with the sample
    window stored in invocation_args. dbt Core passes the window as a
    SampleWindow object, which upload_invocations converts to start and end
    strings; without that the on-run-end hook fails (#542).

    Disabled unless dbt_artifacts_test_expect_sample_window is true: the
    DuckDB tox envs run a model with
    --sample '{"start": "2024-01-01", "end": "2099-12-31"}', then run only
    this test, so the most recent invocation in the table is that run.
    Not run on Fusion, which doesn't put the sample in invocation_args.

    Returns a row if the most recent invocation's invocation_args lacks the
    window's start or end.
*/

{{ config(enabled = var('dbt_artifacts_test_expect_sample_window', false)) }}

with last_invocation as (
    select cast(invocation_args as {{ dbt.type_string() }}) as invocation_args
    from {{ ref('dbt_artifacts', 'invocations') }}
    where run_started_at = (
        select max(run_started_at)
        from {{ ref('dbt_artifacts', 'invocations') }}
    )
)

select invocation_args
from last_invocation
where
    invocation_args not like '%2024-01-01 00:00:00%'
    or invocation_args not like '%2099-12-31 00:00:00%'
