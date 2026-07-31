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

{% macro safe_copy_mapping(dictionary) %}
    {{ dbt_artifacts.raise_equality_warning(dictionary) }}
    {{ return(dbt_artifacts.update_nested_dict(dictionary)) }}
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
                {{ return(_val.strftime(dbt_artifacts.get_strftime_format()) ) }}
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

{% macro raise_equality_warning(dictionary) %}
    {% set is_dev = var('is_development', false) | as_bool %}
    {% if is_dev %}
        {% if dictionary != dbt_artifacts.update_nested_dict(dictionary) %}
             {{ log("Caught on: " ~ dictionary.name, is_dev) }}
            {{ log("ORIGINAL !!! SEE BELOW !!!\n" ~ dictionary) }}
            {{ log("COPY !!! SEE BELOW !!!\n" ~ dbt_artifacts.update_nested_dict(dictionary)) }}

            {{ exceptions.warn("Original mapping and copied mapping do not align! Please validate and disregard if expected.") }}
        {% endif %}
    {% endif %}
{% endmacro %}
