{{ config(
    materialized = "incremental",
    unique_key    = "user_id",
    incremental_strategy = "merge",
    on_schema_change='sync_all_columns'
) }}

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

{% if is_incremental() %}
  -- No specific timestamp filter here, merge will compare all records
  -- based on user_id. If a true updated_at timestamp becomes available
  -- in raw_users, it can be added here for efficiency.
{% endif %}
