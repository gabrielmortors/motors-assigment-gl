{{ config(
    materialized = "incremental",
    unique_key = "user_event_key",
    incremental_strategy = "insert_overwrite",
    partition_by = {
      "field": "event_id",
      "data_type": "string"
    },
    on_schema_change='sync_all_columns'
) }}

with source_events as (
    -- Select from stg_events, which now passes through the rsvps array
    select
        event_id
        , rsvps
        , event_created_at -- Needed for the incremental logic if we filter source_events
    from {{ ref('stg_events') }}
    {% if is_incremental() %}
    -- Optimization: Only process events that are new or have been updated recently.
    -- This assumes stg_events.event_created_at reflects updates to the event or its RSVPs.
    -- The main insert_overwrite logic handles the actual partitioning.
    where event_created_at > (select coalesce(max(event_created_at), '1900-01-01') from {{ this }})
    {% endif %}
)

, rsvps_exploded as (
    select
        se.event_id
        , rsvp.user.user_id::STRING as user_id
        , rsvp.response::STRING as rsvp_response
        , {{ to_timestamp_from_unix('rsvp.mtime') }} as rsvp_last_modified_at
        , rsvp.guests::INT as rsvp_guests
        -- Create a unique key for each RSVP record
        , {{ dbt_utils.generate_surrogate_key(['se.event_id', 'rsvp.user.user_id']) }} as user_event_key
        , se.event_created_at -- To carry over for potential downstream incremental logic or reference
    from source_events se
    cross join unnest(se.rsvps) as rsvp -- Using unnest for Databricks SQL
)

select
    event_id
    , user_id
    , rsvp_response
    , rsvp_last_modified_at
    , rsvp_guests
    , user_event_key
    , event_created_at
from rsvps_exploded

{% if is_incremental() %}
-- This condition ensures that we only overwrite partitions for events that either:
-- 1. Already exist in this table (meaning we might be updating their RSVPs).
-- 2. Are new in the current batch of `rsvps_exploded` (new events with RSVPs).
-- This is crucial for `insert_overwrite` to correctly target partitions.
where event_id in (
    select distinct event_id from {{ this }}
    union -- Using UNION ensures distinct event_ids
    select distinct event_id from rsvps_exploded
)
{% endif %}
