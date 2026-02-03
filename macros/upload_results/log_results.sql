

{% macro log_results(results, src_value) %}
    {% set pipeline = var('pipeline_name')%}
	{% set catalog_name = target.database%}
	{% set schema_nam = target.schema%}
	{% set if_not_exist_create = run_query("CREATE TABLE IF NOT EXISTS "+catalog_name+"."+schema_nam+".dq_load_result_data ( pipeline STRING, model STRING, table_name STRING, catalog_name STRING, test_severity STRING, test_group STRING,dq_rule STRING, test_status STRING, test_message STRING,test_runtime timestamp,test_rundate STRING) USING delta ") %}
  {% if execute %}
  {{ log("= Reuslt summary start =", info=True) }}
  {% set src_details =  fetch_all_source_details(src_value) %}
  {% for res in results -%}
    {% set unique_src_details = fetch_current_test_source(res.node.unique_id, src_details) %}
    {% set query_temp -%}
        select '{{pipeline}}' pipeline, 'rwde' model,
		'{{ unique_src_details.table_name if unique_src_details.table_name else '' }}' as table_name,
        '{{ unique_src_details.catalog if unique_src_details.catalog else '' }}' as catalog_name,
        '{{ unique_src_details.meta.test_severity if "test_severity" in unique_src_details.meta else '' }}' as test_severity,
		'{{ unique_src_details.meta.test_group if "test_group" in unique_src_details.meta else '' }}' as test_group,
        '{{ res.node.unique_id }}' dq_rule,
        '{{ res.status }}' test_status,
        '{{ res.message }}' test_message,
        cast('{{res.timing[0].started_at}}' as timestamp) test_runtime,
        cast (to_date('{{res.timing[0].started_at}}') as string) as test_rundate;
    {%- endset %}
    {{ log(query_temp, info=True) }}
    {% set all_columns = run_query("insert into "+catalog_name+"."+schema_nam+".dq_load_result_data "+query_temp) %}

  {% endfor %}
  {{ log("= Result summary end =", info=True) }}
  {% endif %}

{% endmacro %}

{% macro fetch_all_source_details(src_value) %}
    {% set source_elements = {} %}
    {% for source in src_value -%}
        {% for column_name, column_source in source.columns.items() -%}
            {% do source_elements.update({source.source_name+'_'+source.name+'_'+column_name: {"table_name" : source.name, "catalog": source.database, "schema": source.schema, "test_level":"column", "column_name":column_name, "meta":column_source.meta}}) %}
        {%- endfor %}
        {% do source_elements.update({source.source_name+'_'+source.name: {"table_name" : source.name, "catalog": source.database, "schema": source.schema, "test_level":"table", "column_name":"", "meta":source.meta}}) %}
    {%- endfor %}
    {{return(source_elements)}}
{% endmacro %}
{% macro get_source_details1(src_value) %}
    {% set src_details =  fetch_all_source_details(src_value) %}
    {% set unique_id =  "test.dmi_dq.dbt_expectations_source_expect_column_values_to_not_be_null_rwde_databricks_biomarker_summary_biomarker_effective_datetime.9321b32890" %}
    {% set unique_src_details = fetch_current_test_source(unique_id, src_details) %}
    {% set return_values %}
        '{{ unique_src_details.table_name if unique_src_details.table_name else '' }}' as tbl,
        '{{ unique_src_details.catalog if unique_src_details.catalog else '' }}' as cat,
        '{{ unique_src_details.meta.test_severit if "test_severit" in unique_src_details.meta else '' }}' as typ        
    {%- endset %}
    {{return(return_values)}}
{% endmacro %}
{% macro fetch_current_test_source(unique_id, src_details) %}
    {% for src_key, src_value in src_details.items() -%}        
        {% if src_key in unique_id %}
            {{return(src_value)}}
            {% break %}
        {% endif %}
    {%- endfor %}    
{% endmacro %}

{% macro get_test() %}
    {% set input1 = {'rwde_databricks_biomarker_summary_biomarker_effective_datetime': [{'table_name': 'cancer_patient', 'catalog': '"+catalog_name+"', 'schema': '"+schema_nam+"', 'test_level': 'column', 'column_name': 'patient_id', 'meta': {'test_severity': 'High', 'test_group': 'Column_value_testing'}}]} %}
    {% set find = "test.dmi_dq.dbt_expectations_source_expect_column_values_to_not_be_null_rwde_databricks_biomarker_summary_biomarker_effective_datetime.9321b32890" %}
    {% set output = "default99" %}
    {% for src_key, src_value in input1.items() -%} 
        {% set output = src_value %}      
        {% if src_key in find %}
            {{return(src_value)}}
            {% break %}
        {% endif %}
    {%- endfor %}
    
{% endmacro %}

{% macro log_results_test(results, src) %}
    {% set qry %}
        select cast('{{results}}' as string) as str1, cast('{{src}}' as string) as str2
    {% endset %}
    {% set if_not_exist_create = run_query("CREATE TABLE IF NOT EXISTS "+catalog_name+"."+schema_nam+".dq_load_result_data_test using delta as "+qry) %}
{% endmacro %}
