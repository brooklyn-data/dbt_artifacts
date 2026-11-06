{#-
    Lookback window for the consumption and observability marts.

    Those marts are views over every row ever uploaded, so on a project with
    years of history every query (and every test on them) reads the whole
    history. dbt_artifacts_mart_lookback_days (default 30) bounds them to
    recent days; set it to null to read all history.

    mart_lookback_days() returns the configured number of days, or none when
    the window is turned off.

    mart_lookback_start(align_to_month, min_days) returns a SQL date
    expression for the first UTC day in the window, or none when it is off.
    min_days widens the window for a mart that needs more history (the
    forecast's run-rate days). align_to_month moves the start back to the
    first of its month, so monthly marts never report a partial month.

    mart_lookback_filter(column_expr, lookback_start, pad_days) returns the
    predicate "column_expr >= start - pad_days", or "1 = 1" when the window is
    off. pad_days reads a little earlier than the reported window, for window
    functions and joins that need the row just before it.
-#}

{% macro mart_lookback_days() %}
    {%- set days = var("dbt_artifacts_mart_lookback_days", 30) -%}
    {%- if days is none or (days is string and days | trim | lower in ["", "none", "null"]) -%}
        {{ return(none) }}
    {%- endif -%}
    {%- if (days | int) <= 0 -%}
        {{ exceptions.raise_compiler_error(
            "dbt_artifacts_mart_lookback_days must be a whole number of days greater than 0, or null to read all history. Got: " ~ days
        ) }}
    {%- endif -%}
    {{ return(days | int) }}
{% endmacro %}

{% macro mart_lookback_start(align_to_month=false, min_days=0) %}
    {%- set days = dbt_artifacts.mart_lookback_days() -%}
    {%- if days is none -%}
        {{ return(none) }}
    {%- endif -%}
    {%- set days = [days, min_days | int] | max -%}
    {%- set today = dbt_artifacts.cast_to_utc_date(dbt.current_timestamp()) | trim -%}
    {%- set start = dbt.dateadd("day", -days, today) | trim -%}
    {%- if align_to_month -%}
        {%- set start = dbt.date_trunc("month", start) | trim -%}
    {%- endif -%}
    {{ return("(" ~ start ~ ")") }}
{% endmacro %}

{% macro mart_lookback_filter(column_expr, lookback_start, pad_days=0) %}
    {%- if lookback_start is none -%}
        1 = 1
    {%- elif pad_days | int == 0 -%}
        {{ column_expr }} >= {{ lookback_start }}
    {%- else -%}
        {{ column_expr }} >= {{ dbt.dateadd("day", -(pad_days | int), lookback_start) | trim }}
    {%- endif -%}
{% endmacro %}
