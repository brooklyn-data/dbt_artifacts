{#
    Prints dim_dbt__current_relations as a versioned JSON document, for use as
    dbt deferral state. Emits with print() so `dbt --quiet run-operation` gives
    clean JSON on stdout. Never raises: an absent relation or an empty result
    yields an empty `nodes` object and a warning, leaving the caller to decide.

    Usage:
      dbt --quiet run-operation dbt_artifacts.export_state \
        --args '{schema: dbt_artifacts, target_name: betterdata_prod}' > export.json
#}
{% macro export_state(resource_types=['model', 'seed', 'snapshot'], database=none, schema=none, target_name=none) %}

    {% set state_version = 1 %}
    {% set relation = ref("dim_dbt__current_relations") %}
    {% set source_database = database if database is not none else relation.database %}
    {% set source_schema = schema if schema is not none else relation.schema %}
    {% set target_relation = api.Relation.create(
        database=source_database, schema=source_schema, identifier=relation.identifier
    ) %}

    {% set nodes = {} %}

    {% if execute %}
        {# load_relation (a dbt-core built-in) checks existence without raising,
           unlike selecting from the relation directly, which errors out when
           it is absent. #}
        {% if load_relation(target_relation) is none %}
            {% do log("export_state: " ~ target_relation ~ " does not exist; exporting an empty document", info=False) %}
        {% else %}
            {% set query %}
                select
                    node_id,
                    resource_type,
                    name,
                    package_name,
                    {% if target.type == "sqlserver" %} "database" {% else %} database {% endif %},  -- noqa
                    {% if target.type == "sqlserver" %} "schema" {% else %} schema {% endif %},  -- noqa
                    alias,
                    materialization,
                    checksum,
                    last_success_at,
                    command_invocation_id,
                    target_name
                from {{ target_relation }}
                where resource_type in ({{ "'" ~ resource_types | join("', '") ~ "'" }})
                {% if target_name is not none %} and target_name = '{{ target_name }}' {% endif %}
            {% endset %}

            {% set results = run_query(query) %}

            {% for row in results.rows %}
                {% do nodes.update({
                    row["node_id"]: {
                        "resource_type": row["resource_type"],
                        "name": row["name"],
                        "package_name": row["package_name"],
                        "database": row["database"],
                        "schema": row["schema"],
                        "alias": row["alias"],
                        "materialization": row["materialization"],
                        "checksum": row["checksum"],
                        "last_success_at": row["last_success_at"] | string,
                        "command_invocation_id": row["command_invocation_id"],
                    }
                }) %}
            {% endfor %}

            {% if nodes | length == 0 %}
                {% do log("export_state: no successful executions found in " ~ target_relation ~ "; exporting an empty document", info=False) %}
            {% endif %}
        {% endif %}
    {% endif %}

    {% set document = {
        "dbt_artifacts_state_version": state_version,
        "generated_at": modules.datetime.datetime.now(modules.pytz.utc).isoformat(),
        "source": {
            "database": source_database,
            "schema": source_schema,
            "target_name": target_name,
        },
        "nodes": nodes,
    } %}

    {% do print(tojson(document)) %}

{% endmacro %}
