{% macro update_nested_dict(dictionary) %}
    {% set updated_dict = dictionary.copy() %}
    {% for key, value in dictionary.items() %}
        {% if value is mapping %}
            {# Recursively update nested dictionaries #}
            {% set nested_update = dbt_artifacts.update_nested_dict(dictionary[key]) %}
            {% do updated_dict.update({key: dbt_artifacts.type_handler(nested_update)}) %}
        {% else %}
            {# Update the value dynamically #}
            {% do updated_dict.update({key: dbt_artifacts.type_handler(value)}) %}
        {% endif %}
    {% endfor %}
    {{ return(updated_dict) }}
{% endmacro %}

{% macro safe_copy_mapping(mapping_to_validate, parent_key='') %}
    {% set is_dev = var('is_development', false) | as_bool %}
    {{ log("Checking: " ~ mapping_to_validate.name, is_dev) }}
    {% if not mapping_to_validate.name == 'microbatch' and is_dev %}
        {% if mapping_to_validate != dbt_artifacts.update_nested_dict(mapping_to_validate) %}
            {{ exceptions.raise_compiler_error("Original mapping and copied mapping do not align!") }}
        {% endif %}
    {% endif %}
    {{ log("ORIGINAL !!! ___ !!!") }}
    {{ log(mapping_to_validate) }}
    {{ log("COPY !!! ___ !!!") }}
    {{ log(dbt_artifacts.update_nested_dict(mapping_to_validate)) }}
    {{ return(dbt_artifacts.update_nested_dict(mapping_to_validate)) }}
{% endmacro %}

{% macro type_handler(val) %}
    {% set _val = val %}
    {% if _val is none %}
        {{ return(_val) }}
    {% else %}
        {% if dbt_artifacts.is_serializable(_val) %}
            {{ return(_val) }}
        {% else %}
            {#- this is super wonky, because we're ASSUMING this works if it's not serializable -#}
            {#- there's a real scenario where we attempt this and it just goes sideways -#}
            {% if _val.strftime is not none %}
                {#- convert to string explicitly -#}
                {{ return(_val.strftime("%Y-%m-%dT%H:%M:%S.%f") ) }}
            {% else %}
                {#- just send it -#}
                {{ return(_val | as_text ) }}
            {% endif %}
        {% endif %}
    {% endif %}
{% endmacro %}

{% macro is_serializable(val) %}
    {% if val is string or val is boolean or val is number %}
        {{ return(true) }}
    {% elif val is mapping %}
        {{ return(true) }}
    {% elif val is iterable %}
        {{ return(true) }}
    {% elif val is sequence%}
        {{ return(true) }}
    {% elif val is none %}
        {{ return(true) }}
    {% else %}
        {{ return(false) }}
    {% endif %}
{% endmacro %}
