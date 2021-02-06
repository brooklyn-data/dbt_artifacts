with models as (

    select *
    from {{ ref('stg_dbt__models') }}

),

latest_executions as (

    select *
    from {{ ref('fct_dbt__latest_full_model_executions') }}

),

latest_id as (

    select
        any_value(command_invocation_id) as command_invocation_id
    from latest_executions

),

latest_models as (

    select
        models.node_id,
        models.depends_on_nodes
    from latest_id
    left join models on latest_id.command_invocation_id = models.command_invocation_id


),

node_dependencies as (
    -- Create a row for each model and model dependency, including those where there are no dependencies.

    select
        latest_models.node_id,
        node.value::string as depends_on_node_id,
        regexp_substr(node.value::string, '^([a-z]+)') as depends_on_node_type
    from latest_models,
    lateral flatten(input => latest_models.depends_on_nodes) as node

),

node_dependencies_deduped as (
    -- depends_on_nodes is simply a list of all the ref() statements used in a model, so it may contain duplicates

    select distinct
        node_id,
        depends_on_node_type,
        depends_on_node_id
    from node_dependencies

),

count_model_dependencies as (
    -- Count the number of dependencies a model has to other models

    select
        node_dependencies_deduped.node_id,
        count(
            case when depends_on_node_type = 'model' then 1 end
        ) over (
            partition by node_id
        ) as num_model_dependencies
    from node_dependencies_deduped

),

no_model_dependencies_deduped as (
    -- Find models which depend on no other models (root models)

    select
        node_id
    from count_model_dependencies
    where num_model_dependencies = 0
    group by node_id

),

no_model_dependencies_with_execution_time as (
    -- Models which have no dependencies enriched with execution time

    select
        no_model_dependencies_deduped.node_id,
        latest_executions.execution_time,
        null as depends_on_node_id
    from no_model_dependencies_deduped
    left join latest_executions on no_model_dependencies_deduped.node_id = latest_executions.node_id

),

model_dependencies_with_execution_time as (
    -- Model dependencies enriched with execution time

    select distinct
        node_dependencies_deduped.node_id,
        latest_executions.execution_time,
        depends_on_node_id
    from node_dependencies_deduped
    left join latest_executions on node_dependencies_deduped.node_id = latest_executions.node_id
    where depends_on_node_type = 'model'

),

models_with_dependent_models as (

    select distinct depends_on_node_id as node_id
    from node_dependencies_deduped

),

models_with_no_dependent_models as (

    select
        latest_models.node_id
    from latest_models
    left join models_with_dependent_models
    on latest_models.node_id = models_with_dependent_models.node_id
    where models_with_dependent_models.node_id is null

),

-- We have to coalesce the execution time to 0 for the case of ephemeral models

anchor as (

    select
        models_with_no_dependent_models.node_id,
        coalesce(node_dependencies_deduped.depends_on_node_id, '') as depends_on_node_id,
        coalesce(latest_executions.execution_time, 0) as execution_time
    from models_with_no_dependent_models
    left join node_dependencies_deduped on models_with_no_dependent_models.node_id = node_dependencies_deduped.node_id
    left join latest_executions on models_with_no_dependent_models.node_id = latest_executions.node_id

),

all_needed_dependencies as (

    select
        node_id,
        coalesce(execution_time, 0) as execution_time,
        coalesce(depends_on_node_id, '') as depends_on_node_id
    from no_model_dependencies_with_execution_time
    union
    select
        node_id,
        coalesce(execution_time, 0) as execution_time,
        coalesce(depends_on_node_id, '') as depends_on_node_id
    from model_dependencies_with_execution_time

),

search_path (node_ids, total_time) as (

    select
        array_construct(depends_on_node_id, node_id),
        execution_time
    from anchor
    union all
    select
        array_cat(to_array(all_needed_dependencies.depends_on_node_id), search_path.node_ids) as node_ids,
        all_needed_dependencies.execution_time + search_path.total_time
    from search_path
    left join all_needed_dependencies
    where get(search_path.node_ids, 0) = all_needed_dependencies.node_id

),

longest_path_minutes as (

    select
        -- Remove any empty strings from the beginning of the array that were introduced in search_path to prevent infinite recursion
        case
            when get(node_ids, 0) = ''
            then array_slice(node_ids, 1, -1)
            else node_ids
        end as node_ids,
        total_time/60 as total_minutes
    from search_path
    order by total_time desc
    limit 1

)

select * from longest_path_minutes