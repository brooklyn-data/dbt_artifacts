{% macro copy_model(model) %}
    {% set model_copy = model.copy() %}
    {% do model_copy.pop('raw_code', None) %}
    {% if model_copy.config.begin %}
        {% set _ = model_copy.config.update({"begin": model_copy.config.begin.strftime("%Y-%m-%dT%H:%M:%S.%f")}) %}
    {% endif %}

    {{ return(model_copy) }}
{% endmacro %}
