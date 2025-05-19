{{config(
    materialized = 'table'
)}}

with user_memberships as (
    select * from {{ ref('int_user_memberships_with_groups') }}
),

dim_groups as (
    select * from {{ ref('dim_groups') }}
),

-- Calculate daily membership activity for each group
daily_group_metrics as (
    select
        group_id,
        date(joined_at) as activity_date,
        count(distinct user_id) as new_members,
        count(case when is_early_adopter then 1 end) as new_early_adopters
    from user_memberships
    group by 1, 2
),

-- Add first member joined and latest member joined metrics
group_milestones as (
    select
        group_id,
        min(joined_at) as first_member_joined_at,
        max(joined_at) as last_member_joined_at
    from user_memberships
    group by 1
),

final as (
    select
        g.group_sk,
        dgm.activity_date,
        g.group_id,
        g.group_name,
        
        -- Daily metrics
        dgm.new_members,
        dgm.new_early_adopters,
        
        -- Milestone flags
        case when dgm.activity_date = date(gm.first_member_joined_at) then true else false end as is_first_member_date,
        case when dgm.activity_date = date(gm.last_member_joined_at) then true else false end as is_latest_member_date,
        
        -- Relative time metrics
        datediff(day, g.group_created_at, dgm.activity_date) as days_since_creation
        
    from daily_group_metrics dgm
    inner join dim_groups g on dgm.group_id = g.group_id
    left join group_milestones gm on dgm.group_id = gm.group_id
    where dgm.new_members > 0 or dgm.new_early_adopters > 0
)

select * from final
