{#-
    Generic schema test: fails for any row whose column_name is outside the
    inclusive range [min_value, max_value]. A dependency-free range guard
    (dbt_utils.accepted_range equivalent) used by the consumption/observability
    marts. Null column values are ignored (pair with not_null where required).

    Usage in a model .yml:
        columns:
          - name: pct_of_month_smb
            tests:
              - dbt_artifacts.is_between:
                  min_value: 0
                  max_value: 1
-#}

{% test is_between(model, column_name, min_value, max_value) %}

select {{ column_name }} as value_out_of_range
from {{ model }}
where {{ column_name }} < {{ min_value }}
    or {{ column_name }} > {{ max_value }}

{% endtest %}
