{{ config(
    materialized = "incremental",
    unique_key = "membership_key",
    incremental_strategy = "merge",
    on_schema_change='sync_all_columns'
) }}

with source_users as (
    select
        user_id
        , memberships
        -- Attempt to get a user-level update timestamp if available in raw_users for filtering source
        -- For now, assuming raw_users doesn't have a reliable 'updated_at' for the user record itself.
        -- If raw_users gets an 'updated_at', it could be used here for a pre-filter.
    from {{ ref('raw_users') }}
    -- No pre-filter on source_users for now, as user-level updated_at is not available.
    -- The main incremental logic will rely on joined_at from the memberships.

)

, memberships_exploded as (
    select
        su.user_id::STRING as user_id
        , exploded.group_id::STRING as group_id
        , {{ to_timestamp_from_unix('exploded.joined') }} as joined_at
        , {{ dbt_utils.generate_surrogate_key(['su.user_id', 'exploded.group_id']) }} as membership_key
        , row_number() over (partition by su.user_id, exploded.group_id order by {{ to_timestamp_from_unix('exploded.joined') }} desc) as rn
    from source_users su
    LATERAL VIEW explode(memberships) as exploded -- Using explode for Databricks SQL
)

select
    user_id
    , group_id
    , joined_at
    , membership_key
from memberships_exploded
where rn = 1

{% if is_incremental() %}
  -- Filter based on the joined_at timestamp of the membership itself.
  -- This ensures that if a membership's joined_at time is updated (rare),
  -- or new memberships are added, they are processed.
  -- The where rn = 1 above handles deduplication for the latest record.
  and joined_at > (select coalesce(max(joined_at), '1900-01-01'::timestamp) from {{ this }})
{% endif %}
