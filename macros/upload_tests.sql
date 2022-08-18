{% macro upload_tests(graph) -%}
    {% set src_dbt_tests = source('dbt_artifacts', 'tests') %}
    {% set tests = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "test") %}
        {% do tests.append(node) %}
    {% endfor %}

    {% if tests != [] %}
        {% set test_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(3) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(4) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(5) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(6) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(7) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(8)) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(9) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(10) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(12) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(13)) }}
        from values
        {% for test in tests -%}

            {%- if test.test_metadata is defined -%}
            {%- set test_name = test.test_metadata.name -%}
            {%- set test_type = 'generic' -%}
            
            {%- if test_name == 'relationships' -%}
                {%- set column_name = test.test_metadata.kwargs.field ~ ',' ~ test.test_metadata.kwargs.column_name -%}
            {%- else -%}
                {%- set column_name = test.test_metadata.kwargs.column_name -%}
            {%- endif -%}
            {%- elif test.name is defined -%}
            {%- set test_name = test.name -%}
            {%- set test_type = 'singular' -%}
            {%- endif %}

            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ test.name }}', {# name #}
                '{{ test_name }}', {# short_name #}
                '{{ test_type }}', {# test_type #}
                '{{ test.config.severity }}', {# test_severity_config #}
                '{{ tojson(test.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ process_refs(test.refs) }}', {# model_refs #}
                '{{ process_refs(test.sources, is_src=true) }}', {# source_refs #}
                '{{ test.package_name }}', {# package_name #}
                '{{ test.original_file_path | replace('\\', '\\\\') }}', {# test_path #}
                '{{ tojson(test.tags) }}' {# tags #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_tests.database,
            schema_name=src_dbt_tests.schema,
            table_name=src_dbt_tests.identifier,
            content=test_values
            )
        }}
    {% endif %}
{% endmacro -%}

/*
  return a comma delimited string of the models or sources were related to the test.
    e.g. dim_customers,fct_orders
  behaviour changes slightly with the is_src flag because:
    - models come through as [['model'], ['model_b']]
    - srcs come through as [['source','table'], ['source_b','table_b']]
*/
{% macro process_refs( ref_list, is_src=false ) %}
  {% set refs = [] %}

  {% if ref_list is defined and ref_list|length > 0 %}
      {% for ref in ref_list %}
        {% if is_src %}
          {{ refs.append(ref|join('.')) }}
        {% else %}
          {{ refs.append(ref[0]) }}
        {% endif %} 
      {% endfor %}

      {{ return(refs|join(',')) }}
  {% else %}
      {{ return('') }}
  {% endif %}
{% endmacro %}
