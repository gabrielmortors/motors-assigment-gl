{{ config(
    materialized = "incremental",
    unique_key    = "event_id",
    incremental_strategy = "merge",
    on_schema_change='sync_all_columns',
    partition_by = {
      "field": "date(event_created_at)",
      "data_type": "date"
    }
) }}

with raw_data as (
    select * from {{ ref('raw_events') }}
)

-- Extract base event details without the nested structures
, events as (
    select
        group_id
        , event_name
        , event_description
        , event_created_at
        , event_start_time
        -- Duration already converted from milliseconds to seconds in raw_events.sql using convert_milliseconds_to_seconds macro
        , event_duration_seconds
        , rsvp_limit
        , venue_id
        , event_status
        -- Create a truly unique event_id that distinguishes each occurrence
        , CONCAT(group_id, '-', 
                REGEXP_REPLACE(event_name, '[\s]+', '-'), '-', 
                DATE_FORMAT(event_start_time, 'yyyy-MM-dd-HH-mm')) as event_id
        , rsvps
    from raw_data
)

{% if is_incremental() %}
  -- this filter will only be applied on an incremental run
  -- and will optimize the amount of data scanned from the raw_events model
  select * from events where event_created_at > (select max(event_created_at) from {{ this }})
{% else %}
  select * from events
{% endif %}
