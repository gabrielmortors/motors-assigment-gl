{{config(
    materialized = 'table'
)}}

-- Grain: one row per user-group membership (latest version of each membership)

with user_memberships as (
    select * from {{ ref('int_user_memberships_with_groups') }}
),

dim_users as (
    select * from {{ ref('dim_users') }}
),

dim_groups as (
    select * from {{ ref('dim_groups') }}
),

final as (
    select
        -- Surrogate keys
        um.membership_sk,
        um.user_sk,
        um.group_sk,
        
        -- Natural keys
        um.user_id,
        um.group_id,
        
        -- Membership attributes
        um.joined_at,
        date(um.joined_at) as joined_date,
        um.membership_version_number,
        um.days_from_group_creation_to_join,
        um.is_early_adopter,
        
        -- Group details at time of join
        um.group_name,
        um.group_city,
        um.group_created_at,
        
        -- User details
        um.user_city,
        um.user_country,
        um.user_hometown,
        
        -- Derived metrics
        datediff(day, um.joined_at, current_date()) as membership_age_days,
        datediff(month, um.joined_at, current_date()) as membership_age_months,
        
        -- Status flags
        case when um.membership_version_number = 1 then true else false end as is_active
        
    from user_memberships um
    inner join dim_users u on um.user_sk = u.user_sk
    inner join dim_groups g on um.group_sk = g.group_sk
)

select * from final
