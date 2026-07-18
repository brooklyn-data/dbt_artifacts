{#-
    flatten_json_array(array_column, alias)

    Renders a lateral table-function FROM-clause fragment that explodes an
    array-valued column into one row per element. Intended for use in the
    FROM clause after a comma:

        from my_model
        , {{ dbt_artifacts.flatten_json_array('my_model.depends_on_nodes', 'dep') }}

    The per-element scalar is then accessed as `{{ alias }}.value` (cast as
    needed). On Snowflake the package's depends_on_nodes columns are native
    ARRAY (type_array()), so the input is flattened directly -- no parse_json.

    Snowflake only in v1. Other adapters raise a clear compile error; the model
    that uses this helper is itself gated to Snowflake. Cross-adapter overrides
    (BigQuery unnest, Postgres jsonb_array_elements_text, Trino unnest, Spark
    explode, SQL Server openjson) are fast-follow (O-12 / C-11) and coordinated
    with specs/materialize-docs/design.md.
-#}

{% macro flatten_json_array(array_column, alias) %}
    {{ return(adapter.dispatch('flatten_json_array', 'dbt_artifacts')(array_column, alias)) }}
{% endmacro %}

{% macro default__flatten_json_array(array_column, alias) %}
    {#- The models using this helper are Snowflake-gated, so on other adapters
        this branch is reached only during `dbt parse` (execute == false), never
        at run time. Emit a parse-safe placeholder so parsing succeeds on every
        adapter, and raise a clear error only if a model is actually built on an
        unsupported adapter (execute == true). This keeps the package backwards-
        compatible: a non-Snowflake consumer's `dbt parse`/`dbt run` is unaffected. -#}
    {%- if execute -%}
        {{ exceptions.raise_compiler_error(
            "dbt_artifacts.flatten_json_array() is only implemented for Snowflake in v1 (adapter '"
            ~ target.type
            ~ "' is unsupported for now). The models using it are Snowflake-gated; cross-adapter support is fast-follow O-12 / C-11."
        ) }}
    {%- endif -%}
    (select cast(null as {{ dbt.type_string() }}) as value) as {{ alias }}
{% endmacro %}

{% macro snowflake__flatten_json_array(array_column, alias) %}
    lateral flatten(input => {{ array_column }}) as {{ alias }}
{% endmacro %}
