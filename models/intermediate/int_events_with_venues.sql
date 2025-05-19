with events as (
    select * from {{ ref('stg_events') }}
),

venues as (
    select * from {{ ref('stg_venues') }}
),

-- Add row number to track event versions but keep all records
event_versions as (
    select 
        *,
        row_number() over (
            partition by group_id, event_name, event_start_time, venue_id 
            order by event_created_at desc
        ) as event_version_number
    from events
),

event_with_keys as (
    select
        -- Surrogate keys
        {{ dbt_utils.generate_surrogate_key(['event_versions.group_id', 'event_versions.event_name', 'event_versions.event_start_time', 'event_versions.venue_id']) }} as event_sk
        , {{ dbt_utils.generate_surrogate_key(['venues.venue_id']) }} as venue_sk
        
        -- Event information
        , event_versions.group_id
        , event_versions.event_name
        , event_versions.event_description
        , event_versions.event_created_at
        , event_versions.event_start_time
        , event_versions.event_duration_seconds
        , event_versions.rsvp_limit
        , event_versions.event_status
        , event_versions.event_version_number  -- Include version number for use in marts layer
        
        -- Event status flags for easier filtering
        , case when event_versions.event_status = 'suggested' then true else false end as is_suggested
        , case when event_versions.event_status = 'proposed' then true else false end as is_proposed
        , case when event_versions.event_status = 'cancelled' then true else false end as is_cancelled
        , case when event_versions.event_status = 'past' then true else false end as is_past
        , case when event_versions.event_status = 'upcoming' then true else false end as is_upcoming
        
        -- Venue information
        , venues.venue_id
        , venues.venue_name
        , venues.city as venue_city
        , venues.country as venue_country
        , venues.lat as venue_lat
        , venues.lon as venue_lon
    from event_versions
    left join venues
        on event_versions.venue_id = venues.venue_id
)

select * from event_with_keys
