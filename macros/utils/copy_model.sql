{% macro copy_model(model) %}
    {% set model_copy = model.copy() %}
    {% do model_copy.pop('raw_code', None) %}
    {# We assume that the begin value is a datetime object if not a string#}
    {% if model_copy.config.begin and model_copy.config.begin is not string %}
        {% set _ = model_copy.config.update({"begin": model_copy.config.begin.strftime(dbt_artifacts.get_strftime_format())}) %}
    {% endif %}

    {{ return(model_copy) }}
{% endmacro %}
