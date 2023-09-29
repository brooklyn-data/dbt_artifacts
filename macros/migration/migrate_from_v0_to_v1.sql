{%- macro migrate_from_v0_to_v1(old_database, old_schema, new_database, new_schema) -%}

    {% set migrate_model_executions %}
        insert into {{new_database}}.{{new_schema}}.model_executions (
            command_invocation_id,
            compile_started_at,
            materialization,
            name,
            node_id,
            query_completed_at,
            rows_affected,
            schema,
            status,
            thread_id,
            total_node_runtime,
            was_full_refresh,
            run_started_at
        )
        select
            command_invocation_id,
            compile_started_at,
            model_materialization,
            name,
            node_id,
            query_completed_at,
            rows_affected,
            model_schema,
            status,
            thread_id,
            total_node_runtime,
            was_full_refresh,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.fct_dbt__model_executions
    {% endset %}

    {{ log("Migrating model_executions", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_model_executions }}
    {%- endcall -%}

    {% set migrate_tests %}
        insert into {{new_database}}.{{new_schema}}.tests (
            command_invocation_id,
            depends_on_nodes,
            name,
            node_id,
            package_name,
            tags,
            test_path,
            run_started_at
        )
        select
            command_invocation_id,
            depends_on_nodes,
            name,
            node_id,
            package_name,
            [],
            test_path,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.dim_dbt__tests
    {% endset %}

    {{ log("Migrating tests", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_tests }}
    {%- endcall -%}

    {% set migrate_test_executions %}
        insert into {{new_database}}.{{new_schema}}.test_executions (
            command_invocation_id,
            compile_started_at,
            failures,
            node_id,
            query_completed_at,
            rows_affected,
            status,
            thread_id,
            total_node_runtime,
            was_full_refresh,
            run_started_at
        )
        select
            command_invocation_id,
            compile_started_at,
            null,
            node_id,
            query_completed_at,
            rows_affected,
            status,
            thread_id,
            total_node_runtime,
            was_full_refresh,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.fct_dbt__test_executions
    {% endset %}

    {{ log("Migrating test_executions", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_test_executions }}
    {%- endcall -%}

    {% set migrate_models %}
        insert into {{new_database}}.{{new_schema}}.models (
            checksum,
            command_invocation_id,
            database,
            depends_on_nodes,
            materialization,
            name,
            node_id,
            package_name,
            path,
            schema,
            run_started_at
        )
        select
            checksum,
            command_invocation_id,
            model_database,
            depends_on_nodes,
            model_materialization,
            name,
            node_id,
            package_name,
            model_path,
            model_schema,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.dim_dbt__models
    {% endset %}

    {{ log("Migrating models", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_models }}
    {%- endcall -%}

    {% set migrate_seeds %}
        insert into {{new_database}}.{{new_schema}}.seeds (
            checksum,
            command_invocation_id,
            database,
            name,
            node_id,
            package_name,
            path,
            schema,
            run_started_at
        )
        select
            checksum,
            command_invocation_id,
            seed_database,
            name,
            node_id,
            package_name,
            seed_path,
            seed_schema,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.dim_dbt__seeds
    {% endset %}

    {{ log("Migrating seeds", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_seeds }}
    {%- endcall -%}

    {% set migrate_seed_executions %}
        insert into {{new_database}}.{{new_schema}}.seed_executions (
            command_invocation_id,
            compile_started_at,
            materialization,
            name,
            node_id,
            query_completed_at,
            rows_affected,
            schema,
            status,
            thread_id,
            total_node_runtime,
            was_full_refresh,
            run_started_at
        )
        select
            command_invocation_id,
            compile_started_at,
            'seed',
            name,
            node_id,
            query_completed_at,
            rows_affected,
            seed_schema,
            status,
            thread_id,
            total_node_runtime,
            was_full_refresh,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.fct_dbt__seed_executions
    {% endset %}

    {{ log("Migrating seed_executions", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_seed_executions }}
    {%- endcall -%}

    {% set migrate_exposures %}
        insert into {{new_database}}.{{new_schema}}.exposures (
            command_invocation_id,
            depends_on_nodes,
            description,
            maturity,
            name,
            node_id,
            owner,
            package_name,
            path,
            type,
            url,
            run_started_at
        )
        select
            command_invocation_id,
            array_agg(output_feeds), {#- Here we un-flatten the transformation originally done -#}
            null,
            any_value(maturity) as maturity,
            name,
            node_id,
            null, {#- v0 is a string, v1 is a variant -#}
            any_value(package_name) as package_name,
            null,
            any_value(type) as type,
            null,
            any_value(artifact_generated_at) as artifact_generated_at
        from {{old_database}}.{{old_schema}}.dim_dbt__exposures
        group by command_invocation_id, node_id, name, artifact_generated_at
    {% endset %}

    {{ log("Migrating exposures", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_exposures }}
    {%- endcall -%}

    {% set migrate_snapshots %}
        insert into {{new_database}}.{{new_schema}}.snapshots (
            checksum,
            command_invocation_id,
            database,
            depends_on_nodes,
            name,
            node_id,
            package_name,
            path,
            schema,
            strategy,
            run_started_at
        )
        select
            checksum,
            command_invocation_id,
            snapshot_database,
            depends_on_nodes,
            name,
            node_id,
            package_name,
            snapshot_path,
            snapshot_schema,
            null,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.dim_dbt__snapshots
    {% endset %}

    {{ log("Migrating snapshots", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_snapshots }}
    {%- endcall -%}

    {% set migrate_snapshot_executions %}
        insert into {{new_database}}.{{new_schema}}.snapshot_executions (
            command_invocation_id,
            compile_started_at,
            materialization,
            name,
            node_id,
            query_completed_at,
            rows_affected,
            schema,
            status,
            thread_id,
            total_node_runtime,
            was_full_refresh,
            run_started_at
        )
        select
            command_invocation_id,
            compile_started_at,
            'snapshot',
            name,
            node_id,
            query_completed_at,
            rows_affected,
            snapshot_schema,
            status,
            thread_id,
            total_node_runtime,
            was_full_refresh,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.fct_dbt__snapshot_executions
    {% endset %}

    {{ log("Migrating snapshot_executions", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_snapshot_executions }}
    {%- endcall -%}

    {% set migrate_sources %}
        insert into {{new_database}}.{{new_schema}}.sources (
            command_invocation_id,
            database,
            freshness,
            identifier,
            loaded_at_field,
            loader,
            name,
            node_id,
            schema,
            source_name,
            run_started_at
        )
        select
            command_invocation_id,
            node_database,
            parse_json('[{"error_after":{"count":null,"period":null},"filter":null,"warn_after":{"count":null,"period":null}}]'),
            name,
            null,
            source_loader,
            name,
            node_id,
            source_schema,
            source_name,
            artifact_generated_at
        from {{old_database}}.{{old_schema}}.dim_dbt__sources
    {% endset %}

    {{ log("Migrating sources", info=True) }}
    {%- call statement(auto_begin=True) -%}
        {{ migrate_sources }}
    {%- endcall -%}

    {{ log("Migration complete. You can now safely delete any data from before 1.0.0", info=True) }}
{%- endmacro -%}
