{# dbt doesn't like us ref'ing in an operation so we fetch the info from the graph #}

{% macro upload_results(results) -%}

    {#
        dbt Core only fires on-run-end for commands that execute nodes. Fusion
        also fires it for `compile` and `show` (including editor previews),
        which would upload a phantom `inline` model and an invocation on every
        call. Skip those so both engines record the same invocations.
    #}
    {% set skipped_commands = ['compile', 'show'] %}

    {% if execute and invocation_args_dict.get('which') not in skipped_commands %}

        {% set upload_manifest = var('dbt_artifacts_upload_manifest', true) %}
        {# A var set from env_var() arrives as a string, and the string 'false' is truthy in Jinja #}
        {% if upload_manifest is string %}
            {% set upload_manifest = upload_manifest | trim | lower not in ['false', '0'] %}
        {% endif %}

        {% set datasets_to_load = ['invocations'] %}

        {% if upload_manifest %}
            {% set datasets_to_load = ['exposures', 'seeds', 'snapshots', 'sources', 'tests', 'models'] + datasets_to_load %}
        {% endif %}

        {% if results != [] %}
            {# When executing, and results are available, then upload the results #}
            {% set datasets_to_load = ['model_executions', 'seed_executions', 'test_executions', 'snapshot_executions'] + datasets_to_load %}
        {% endif %}

        {#
            Rows per insert statement. BigQuery and Trino get smaller chunks because their query-text limits
            (Trino's query.max-length, for example) reject large inserts. dbt_artifacts_insert_batch_size
            overrides these per dataset: its keys are 'models', 'default' (every other dataset) or a dataset
            name, and any key it leaves out keeps the value below.
        #}
        {% set small_batches = target.type in ['bigquery', 'trino'] %}
        {% set batch_sizes = {
            'models': 50 if small_batches else 100,
            'default': 300 if small_batches else 5000
        } %}
        {% set configured_batch_sizes = var('dbt_artifacts_insert_batch_size', {}) %}
        {% if configured_batch_sizes is not mapping %}
            {% do exceptions.raise_compiler_error(
                "dbt_artifacts_insert_batch_size must be a mapping of dataset name (or 'models' / 'default') to rows per insert, got: "
                ~ configured_batch_sizes
            ) %}
        {% endif %}
        {% do batch_sizes.update(configured_batch_sizes) %}

        {# Upload each data set in turn #}
        {% for dataset in datasets_to_load %}

            {% do log("Uploading " ~ dataset.replace("_", " "), true) %}

            {# Get the results that need to be uploaded #}
            {% set objects = dbt_artifacts.get_dataset_content(dataset) %}

            {# Upload in chunks to reduce the query size #}
            {% set upload_limit = batch_sizes.get(dataset, batch_sizes['default']) | int %}
            {% if upload_limit < 1 %}
                {% do exceptions.raise_compiler_error(
                    "dbt_artifacts_insert_batch_size for '" ~ dataset ~ "' must be a whole number of at least 1, got: "
                    ~ batch_sizes.get(dataset, batch_sizes['default'])
                ) %}
            {% endif %}

            {# Wrap the chunked inserts in a transaction, where the dialect supports it #}
            {{ dbt_artifacts.begin_transaction() }}

            {# Loop through each chunk in turn #}
            {% for i in range(0, objects | length, upload_limit) -%}

                {# Get just the objects to load on this loop #}
                {% set content = dbt_artifacts.get_table_content_values(dataset, objects[i: i + upload_limit]) %}

                {# Insert the content into the metadata table #}
                {{ dbt_artifacts.insert_into_metadata_table(
                    dataset=dataset,
                    fields=dbt_artifacts.get_column_name_list(dataset),
                    content=content
                    )
                }}

            {# Loop the next 'chunk' #}
            {% endfor %}

            {{ dbt_artifacts.end_transaction() }}

        {# Loop the next 'dataset' #}
        {% endfor %}

    {% endif %}

{%- endmacro %}
