{{config(
    materialized = 'table'
)}}

with user_memberships as (
    select * from {{ ref('int_user_memberships_with_groups') }}
),

-- Take the latest user data from each user's memberships
user_data as (
    select
        user_id,
        user_sk,
        user_city,
        user_country,
        user_hometown,
        min(membership_version_number) as latest_membership
    from user_memberships
    group by 1, 2, 3, 4, 5
),

-- Get additional metrics from user activity across groups
user_metrics as (
    select
        user_id,
        count(distinct group_id) as total_groups_joined,
        min(joined_at) as first_joined_at,
        max(joined_at) as last_joined_at,
        count(case when is_early_adopter then 1 end) as early_adopter_count
    from user_memberships
    group by 1
),

final as (
    select
        u.user_sk,
        u.user_id,
        u.user_city,
        u.user_country,
        u.user_hometown,
        m.total_groups_joined,
        m.first_joined_at,
        m.last_joined_at,
        m.early_adopter_count,
        case 
            when m.early_adopter_count > 0 then true 
            else false 
        end as is_any_early_adopter,
        case 
            when m.early_adopter_count > 2 then true 
            else false 
        end as is_frequent_early_adopter
    from user_data u
    left join user_metrics m on u.user_id = m.user_id
)

select * from final
