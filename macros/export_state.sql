{#
    Prints dim_dbt__current_relations as a versioned JSON document, for use as
    dbt deferral state. Emits with print() so `dbt --quiet run-operation` gives
    clean JSON on stdout. Never raises for a missing relation, an empty
    resource_types list, or a zero-row result: each yields an empty `nodes`
    object and a warning, leaving the caller to decide. Raises only on
    invalid arguments (an unknown resource_type, or a database/schema value
    that isn't a safe identifier).

    Emits one node per node_id. dim_dbt__current_relations is grained on
    (node_id, target_name), since several targets can write to the same
    artifacts tables; when target_name is given, each node's row for that
    target is used, and when it isn't, each node's most recently completed
    success across all targets is used, matching the single-target-project
    behaviour where there is only ever one target to pick from.

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
       constrained to a known set (target names are project-specific) and is not
       interpolated into SQL at all — see the row loop below — so it needs no
       validation here. #}
    {% set known_resource_types = ['model', 'seed', 'snapshot'] %}
    {% for resource_type in resource_types %}
        {% if resource_type not in known_resource_types %}
            {% do exceptions.raise_compiler_error(
                "export_state: unknown resource_type '" ~ resource_type ~ "'; expected one of " ~ known_resource_types | join(", ")
            ) %}
        {% endif %}
    {% endfor %}

    {# Not an exhaustive identifier grammar: the point is only to exclude
       quotes, semicolons, whitespace and backslashes (the characters that
       could break out of a quoted identifier or a SQL string literal),
       while still accepting what real warehouses use here in practice —
       including hyphens, which are near-universal in BigQuery project IDs
       used as `database`. #}
    {% set safe_identifier_pattern = '^[A-Za-z0-9_$.\-]+$' %}
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
        {% if resource_types | length == 0 %}
            {# An empty IN (...) list is invalid SQL on most adapters; treat
               "nothing requested" the same as "nothing found". #}
            {% do log("export_state: resource_types is empty; exporting an empty document", info=False) %}
        {% elif load_relation(target_relation) is none %}
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
            {% endset %}

            {% set results = run_query(query) %}

            {# dim_dbt__current_relations is grained on (node_id,
               target_name): several targets writing to the same artifacts
               tables can each have their own latest success for the same
               node. Two cases:
                 - target_name given: at most one row per node_id already
                   matches it, so filtering is a straight lookup.
                 - target_name not given: more than one row per node_id can
                   come back (one per target that has ever built the node).
                   Collapse to one, keeping the most recently completed
                   success, so the single-target-project default behaviour
                   (one row per node) is unchanged and the multi-target case
                   picks the truly freshest relation instead of an arbitrary
                   target's.
               `last_success_at_sort_keys` holds the raw (pre-formatting)
               completion time used only for that comparison; it never
               reaches the emitted document. #}
            {% set last_success_at_sort_keys = {} %}

            {# target_name is project-specific — not a closed set like
               resource_types — so it isn't validated or interpolated into
               SQL at all. Quote-doubling would not be a safe escape on
               every adapter this package supports: Snowflake, BigQuery,
               Spark and Databricks treat backslash as an escape character
               in string literals, so a value ending in an odd run of
               backslashes could desynchronise a doubled quote and reopen
               the hole. Filtering here in Jinja, over a result set that is
               at most hundreds of rows, avoids the per-adapter escaping
               question entirely. #}
            {% for row in results.rows %}
                {% if target_name is none or row["target_name"] == target_name %}
                    {% set completed_at = row["last_success_at"] %}
                    {% set current_best = last_success_at_sort_keys.get(row["node_id"]) %}
                    {# A specific target_name already guarantees at most one
                       matching row per node_id, so every match wins
                       outright. With no target_name, only overwrite the
                       node's current winner when this row is strictly more
                       recent; a null completion time never displaces an
                       existing real one, but still seeds the entry the
                       first time a node is seen. #}
                    {% set wins = target_name is not none
                        or row["node_id"] not in nodes
                        or (completed_at is not none and (current_best is none or completed_at > current_best)) %}
                    {% if wins %}
                        {% set last_success_at = none %}
                        {% if completed_at is not none %}
                            {% set last_success_at = completed_at %}
                            {# Every adapter this package writes to records
                               query_completed_at from dbt's own UTC
                               run-results timing. A value that comes back
                               with no tzinfo (e.g. Postgres/Redshift's
                               timestamp-without-time-zone) is UTC wall-clock
                               time, not an unknown offset, so attaching it
                               explicitly turns the naive value into a real
                               instant. A value that already carries tzinfo
                               (e.g. Snowflake's TIMESTAMP_TZ) is left as-is.
                               isoformat() then gives the `T` separator and
                               explicit offset the README documents, instead
                               of the space-separated, offset-less string
                               `| string` produced. #}
                            {% if last_success_at.tzinfo is none %}
                                {% set last_success_at = last_success_at.replace(tzinfo=modules.pytz.utc) %}
                            {% endif %}
                            {% set last_success_at = last_success_at.isoformat() %}
                        {% endif %}
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
                                "last_success_at": last_success_at,
                                "command_invocation_id": row["command_invocation_id"],
                            }
                        }) %}
                        {% do last_success_at_sort_keys.update({row["node_id"]: completed_at}) %}
                    {% endif %}
                {% endif %}
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
