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

    {# `resource_types` is interpolated straight into an IN (...) list below, and
       `source_database`/`source_schema` are interpolated indirectly: they become
       the FROM-clause relation via api.Relation.create(), whose quoted() wraps
       each part in the adapter's quote character but does not escape a quote
       character embedded in the value, so an unvalidated value could still break
       out of the quoted identifier. Validate both, ahead of any query, so a bad
       value fails loudly instead of reaching the database. This is the one place
       this macro may raise: validation happens before querying starts, so the
       "never raises on a missing relation or zero rows" contract, which is about
       behaviour once the query runs, is untouched. `target_name` is not
       constrained to a known set (target names are project-specific), so it is
       escaped as a SQL string literal instead, where it is used below. #}
    {% set known_resource_types = ['model', 'seed', 'snapshot'] %}
    {% for resource_type in resource_types %}
        {% if resource_type not in known_resource_types %}
            {% do exceptions.raise_compiler_error(
                "export_state: unknown resource_type '" ~ resource_type ~ "'; expected one of " ~ known_resource_types | join(", ")
            ) %}
        {% endif %}
    {% endfor %}

    {% set safe_identifier_pattern = '^[A-Za-z_][A-Za-z0-9_]*$' %}
    {% for value, label in [(source_database, 'database'), (source_schema, 'schema')] %}
        {% if not modules.re.fullmatch(safe_identifier_pattern, value) %}
            {% do exceptions.raise_compiler_error(
                "export_state: unsafe " ~ label ~ " value '" ~ value ~ "'; expected a plain SQL identifier matching " ~ safe_identifier_pattern
            ) %}
        {% endif %}
    {% endfor %}

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
                {# resource_types is validated above against a closed set, so no
                   escaping is needed here. target_name is project-specific and
                   not validated against a known set, so escape it as a SQL
                   string literal by doubling embedded single quotes. #}
                {% if target_name is not none %} and target_name = '{{ target_name | replace("'", "''") }}' {% endif %}
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
