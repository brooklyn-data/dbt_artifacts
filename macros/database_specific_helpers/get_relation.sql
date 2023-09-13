{% macro get_relation(get_relation_name) %}
    {% if execute %}
        {% set model_get_relation_node = graph.nodes.values() | selectattr('name', 'equalto', get_relation_name) | first %}
        {% set relation = api.Relation.create(
            database = model_get_relation_node.database,
            schema = model_get_relation_node.schema,
            identifier = model_get_relation_node.alias
        )
        %}
        {% do return(relation) %}
    {% else %}
        {% do return(api.Relation.create()) %}
    {% endif %}
{% endmacro %}
