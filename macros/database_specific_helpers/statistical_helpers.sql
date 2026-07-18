{#-
    Statistical helpers for the performance-baseline math (observability marts).

    Both macros are aggregate expressions intended for use in GROUP BY queries
    (e.g. per-day, per-node medians). The default__ implementations use the
    ANSI ordered-set aggregate percentile_cont(fraction) within group
    (order by ...), which Snowflake supports natively as an aggregate, so no
    snowflake__ override is required. Non-Snowflake overrides (SQL Server
    window-only syntax, Spark approx_percentile) are fast-follow O-12.
-#}

{#- MEDIAN -#}

{% macro median(column_expr) %}
    {{ return(adapter.dispatch('median', 'dbt_artifacts')(column_expr)) }}
{% endmacro %}

{% macro default__median(column_expr) %}
    percentile_cont(0.5) within group (order by {{ column_expr }})
{% endmacro %}

{#- PERCENTILE (arbitrary fraction in [0, 1]) -#}

{% macro percentile(column_expr, fraction) %}
    {{ return(adapter.dispatch('percentile', 'dbt_artifacts')(column_expr, fraction)) }}
{% endmacro %}

{% macro default__percentile(column_expr, fraction) %}
    percentile_cont({{ fraction }}) within group (order by {{ column_expr }})
{% endmacro %}

{#- P95 -- thin sugar over percentile(col, 0.95); not dispatched. -#}

{% macro p95(column_expr) %}
    {{ dbt_artifacts.percentile(column_expr, 0.95) }}
{% endmacro %}
