with raw_data as (
    select * from {{ ref('raw_users') }}
),

users as (
    select
        user_id
        , city
        , country
        , hometown
    from raw_data
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

select * from users
