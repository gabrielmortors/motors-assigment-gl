with events as (
    select * from {{ ref('stg_events') }}
),

venues as (
    select * from {{ ref('stg_venues') }}
),

event_with_keys as (
    select
        -- Surrogate keys
        {{ dbt_utils.generate_surrogate_key(['events.group_id', 'events.event_name']) }} as event_sk
        , {{ dbt_utils.generate_surrogate_key(['venues.venue_id']) }} as venue_sk
        
        -- Event information
        , events.group_id
        , events.event_name
        , events.event_description
        , events.event_created_at
        , events.event_start_time
        , events.event_duration_seconds
        , events.rsvp_limit
        , events.event_status
        
        -- Venue information
        , venues.venue_id
        , venues.venue_name
        , venues.city as venue_city
        , venues.country as venue_country
        , venues.lat as venue_lat
        , venues.lon as venue_lon
    from events
    left join venues
        on events.venue_id = venues.venue_id
)

select * from event_with_keys
