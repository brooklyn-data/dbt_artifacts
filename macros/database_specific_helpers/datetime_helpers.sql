{#-
    cast_to_utc_date(column_expr)

    Converts a stored run timestamp to its UTC calendar date. Shared
    infrastructure for every daily-grain mart in the consumption and
    observability features.

    Storage assumption (Snowflake): dbt captures run_started_at (and the
    execution-level *_started_at / *_completed_at columns) in UTC, and the
    package stores them via type_timestamp(), which on Snowflake is
    TIMESTAMP_NTZ -- a wall-clock value carrying no timezone. Casting a
    TIMESTAMP_NTZ to date simply truncates to the date part, so the result is
    invariant to the session TIMEZONE setting and is already the correct UTC
    date. convert_timezone() is deliberately NOT used: on an NTZ input it
    assumes the value is in the session timezone and would reintroduce session
    dependence, corrupting the date near midnight.
-#}

{% macro cast_to_utc_date(column_expr) %}
    {{ return(adapter.dispatch('cast_to_utc_date', 'dbt_artifacts')(column_expr)) }}
{% endmacro %}

{% macro default__cast_to_utc_date(column_expr) %}
    cast({{ column_expr }} as date)
{% endmacro %}

{% macro snowflake__cast_to_utc_date(column_expr) %}
    {#- run_started_at is TIMESTAMP_NTZ holding dbt's UTC timestamp; a direct
        date cast yields the UTC calendar date and is session-TZ invariant. -#}
    cast({{ column_expr }} as date)
{% endmacro %}
