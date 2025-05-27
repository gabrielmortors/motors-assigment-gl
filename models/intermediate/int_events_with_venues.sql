{{ config(
    materialized = "incremental",
    unique_key    = "event_id",
    incremental_strategy = "merge",
    partition_by = "event_created_at",
    on_schema_change='sync_all_columns'
) }}

with events as (
    select * from {{ ref('stg_events') }}
    {% if is_incremental() %}
    -- For incremental runs, only process events from stg_events that are new or updated
    -- since the last run of this model.
    where event_created_at > (select max(event_created_at) from {{ this }})
    {% endif %}
)

, venues as (
    select * from {{ ref('stg_venues') }}
)

-- Add row number to track event versions and use the event_id from staging
, event_versions as (
    select 
        *
        -- Use the event_id directly from staging, which now uniquely identifies each occurrence
        , row_number() over (
            partition by event_id 
            order by event_created_at desc
        ) as event_version_number
    from events
)

-- Keep only the latest version of each event
, events_latest as (
    select * 
    from event_versions
    where event_version_number = 1
),

event_with_keys as (
    select
        -- Surrogate keys
        events_latest.event_id as event_sk -- Use event_id from stg_events as the surrogate key
        , {{ dbt_utils.generate_surrogate_key(['venues.venue_id']) }} as venue_sk
        
        -- Natural key (crucial for deduplication)
        , events_latest.event_id
        
        -- Event information
        , events_latest.group_id
        , events_latest.event_name
        , events_latest.event_description_clean as event_description
        , events_latest.event_created_at
        , events_latest.event_start_time
        , events_latest.event_duration_seconds
        , events_latest.rsvp_limit
        , events_latest.event_status
        , events_latest.event_version_number
        
        -- Event status flags for easier filtering
        , case when events_latest.event_status = 'suggested' then true else false end as is_suggested
        , case when events_latest.event_status = 'proposed' then true else false end as is_proposed
        , case when events_latest.event_status = 'cancelled' then true else false end as is_cancelled
        , case when events_latest.event_status = 'past' then true else false end as is_past
        , case when events_latest.event_status = 'upcoming' then true else false end as is_upcoming
        
        -- Venue information
        , venues.venue_id
        , venues.venue_name
        , venues.city as venue_city
        , venues.country as venue_country
        , venues.lat as venue_lat
        , venues.lon as venue_lon
    from events_latest
    left join venues on events_latest.venue_id = venues.venue_id
)

select * from event_with_keys
