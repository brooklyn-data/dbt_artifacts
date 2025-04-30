{% macro get_dataset_content(dataset) %}

    {% if dataset in ['model_executions', 'seed_executions', 'test_executions', 'snapshot_executions'] %}
        {# Executions make use of the results object #}
        {% set objects = results | selectattr("node.resource_type", "equalto", dataset.split("_")[0]) | list %}
    {% elif dataset in ['seeds', 'snapshots', 'tests', 'models'] %}
        {# Use the nodes in the [graph](https://docs.getdbt.com/reference/dbt-jinja-functions/graph) to extract details #}
        {% set objects = graph.nodes.values() | selectattr("resource_type", "equalto", dataset[:-1]) | list %}
        {# Optionally, filter by package_name #}
        {% if var("artifacts_upload_packages", "all") != "all" %}
            {% set objects = (objects | selectattr("package_name", "in", var("artifacts_upload_packages")) | list) %}
        {% endif %}
    {% elif dataset in ['exposures', 'sources'] %}
        {# Use the [graph](https://docs.getdbt.com/reference/dbt-jinja-functions/graph) to extract details #}
        {% set objects = graph.get(dataset).values() | list %}
    {% elif dataset == 'invocations' %}
        {#
            Invocations doesn't need anything input, but we include this so that it will still be picked up
            as part of the loop below - the length must be >0 to allow for an upload, hence the empty string
        #}
        {% set objects = [''] %}
    {% endif %}

    {{ return(objects) }}

{% endmacro %}
