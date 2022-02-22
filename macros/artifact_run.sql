-- This ID provides a reliable ID, regardless of whether running in a local or cloud environment.
{% macro make_artifact_run_id() %}
    sha2_hex(coalesce(dbt_cloud_run_id::string, command_invocation_id::string), 256)
{% endmacro %}
