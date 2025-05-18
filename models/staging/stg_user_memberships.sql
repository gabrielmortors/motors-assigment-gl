with raw_data as (
    select * from {{ ref('raw_users') }}
),

-- Extract memberships from array to create a normalized memberships table
user_memberships as (
    select
        user_id
        , exploded.group_id as group_id
        , from_unixtime(exploded.joined/1000) as joined_at
    from 
        raw_data
        LATERAL VIEW EXPLODE(memberships) exploded_table AS exploded
)

select * from user_memberships
