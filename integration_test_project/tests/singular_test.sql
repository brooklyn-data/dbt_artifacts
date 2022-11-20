{% if target.name == 'sqlserver' %}
select 1 as failures from (values(2)) as tab(col) where 1 = 2
{% else %}
select 1 as failures from (select 2) where 1 = 2
{% endif %}
