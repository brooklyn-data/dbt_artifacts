{#-
    Generic schema test: fails for any row whose column_name falls outside the
    inclusive range [min_value, max_value]. Either bound may be omitted (null)
    for an open-ended check. A dependency-free range guard
    (dbt_utils.accepted_range equivalent) used by the consumption/observability
    marts. Null column values are ignored (pair with not_null where required).

    Usage in a model .yml:
        columns:
          - name: pct_of_month_smb
            tests:
              - dbt_artifacts.is_between: {min_value: 0, max_value: 1}
          - name: runtime_regression_ratio
            tests:
              - dbt_artifacts.is_between: {min_value: 0}   # >= 0, no upper bound
-#}

{% test is_between(model, column_name, min_value=none, max_value=none) %}

select {{ column_name }} as value_out_of_range
from {{ model }}
where
    {% if min_value is not none %}{{ column_name }} < {{ min_value }}{% else %}1 = 0{% endif %}
    or {% if max_value is not none %}{{ column_name }} > {{ max_value }}{% else %}1 = 0{% endif %}

{% endtest %}
