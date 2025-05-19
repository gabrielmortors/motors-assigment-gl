with user_memberships as (
    select * from {{ ref('stg_user_memberships') }}
),

users as (
    select * from {{ ref('stg_users') }}
),

groups as (
    select * from {{ ref('stg_groups') }}
),

-- Add row numbers to identify the latest version of each membership
membership_versions as (
    select 
        *,
        row_number() over (
            partition by user_id, group_id 
            order by joined_at desc
        ) as membership_version_number
    from user_memberships
),

memberships_with_keys as (
    select
        -- Surrogate keys
        {{ dbt_utils.generate_surrogate_key(['membership_versions.user_id', 'membership_versions.group_id']) }} as membership_sk
        , {{ dbt_utils.generate_surrogate_key(['membership_versions.user_id']) }} as user_sk
        , {{ dbt_utils.generate_surrogate_key(['membership_versions.group_id']) }} as group_sk
        
        -- User information
        , users.user_id
        , users.city as user_city
        , users.country as user_country
        , users.hometown as user_hometown
        
        -- Group information
        , groups.group_id
        , groups.group_name
        , groups.city as group_city
        , groups.created_at as group_created_at
        
        -- Membership information
        , membership_versions.joined_at
        , membership_versions.membership_version_number
        , DATEDIFF(day, groups.created_at, membership_versions.joined_at) as days_from_group_creation_to_join
        
        -- Calculated fields for analysis
        , CASE 
            WHEN DATEDIFF(day, groups.created_at, membership_versions.joined_at) <= 30 THEN true 
            ELSE false 
          END as is_early_adopter
    from membership_versions
    left join users
        on membership_versions.user_id = users.user_id
    left join groups
        on membership_versions.group_id = groups.group_id
)

select * from memberships_with_keys
