{{config(
    materialized = 'table'
)}}

{% set large_group_threshold = 100 %}
{% set medium_group_threshold = 50 %}
{% set new_group_days_threshold = 90 %}
{% set established_group_days_threshold = 365 %}

with user_memberships as (
    select * from {{ ref('int_user_memberships_with_groups') }}
),

-- Take the unique group data from memberships (descriptive attributes)
group_data as (
    select distinct
        group_id,
        group_sk,
        group_name,
        group_city,
        group_created_at
    from user_memberships
),

-- Get current snapshot metrics
group_metrics as (
    select
        group_id,
        count(distinct user_id) as total_members,
        count(case when is_early_adopter then 1 end) as early_adopter_count,
        count(case when membership_version_number = 1 then 1 end) as active_memberships
    from user_memberships
    group by 1
),

final as (
    select
        g.group_sk,
        g.group_id,
        g.group_name,
        g.group_city,
        g.group_created_at,
        datediff(day, g.group_created_at, current_date()) as days_since_creation,
        
        -- Current snapshot counts (as of last model run)
        m.total_members,
        m.early_adopter_count,
        m.active_memberships,
        
        -- Derived classification attributes for filtering
        case 
            when m.total_members > {{ large_group_threshold }} then 'Large'
            when m.total_members > {{ medium_group_threshold }} then 'Medium' 
            else 'Small' 
        end as group_size_category,
        
        case
            when datediff(day, g.group_created_at, current_date()) < {{ new_group_days_threshold }} then 'New'
            when datediff(day, g.group_created_at, current_date()) < {{ established_group_days_threshold }} then 'Established'
            else 'Mature'
        end as group_age_category
    from group_data g
    left join group_metrics m on g.group_id = m.group_id
)

select * from final
