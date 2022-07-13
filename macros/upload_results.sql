{% macro upload_results(results) -%}
    {% if execute %}
        {% if results != [] %}
            {% do log("Uploading model executions", true) %}
            {% do dbt_artifacts.upload_model_executions(results) %}
            {% do log("Uploading test executions", true) %}
            {% do dbt_artifacts.upload_test_executions(results) %}
        {% endif %}
        {% do log("Uploading models", true) %}
        {% do dbt_artifacts.upload_models(graph) %}
        {% do log("Uploading tests", true) %}
        {% do dbt_artifacts.upload_tests(graph) %}
        {% do log("Uploading exposures", true) %}
        {% do dbt_artifacts.upload_exposures(graph) %}
        {% do log("Uploading seeds", true) %}
        {% do dbt_artifacts.upload_seeds(graph) %}
        {% do log("Uploading snapshots", true) %}
        {% do dbt_artifacts.upload_snapshots(graph) %}
    {% endif %}
{%- endmacro %}

