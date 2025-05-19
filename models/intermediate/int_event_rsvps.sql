with rsvps as (
    select * from {{ ref('stg_rsvps') }}
)

, events_with_venues as (
    select * from {{ ref('int_events_with_venues') }}
)

, users as (
    select * from {{ ref('stg_users') }}
)

-- Deduplicate RSVPs to get only the latest response per user per event
, rsvps_latest as (
    select *
    from (
        select
            r.*
            , row_number() over (
                partition by event_id, user_id
                order by rsvp_time desc
            ) as rsvp_version_number
        from rsvps r
    )
    where rsvp_version_number = 1 -- Keep only the latest response
)

-- Join with events_with_venues using the natural event_id (simplified approach)
, rsvps_with_keys as (
    select
        -- Surrogate keys (using event_id for truly unique events)
        {{ dbt_utils.generate_surrogate_key(['r.user_id', 'r.event_id']) }} as rsvp_sk
        , {{ dbt_utils.generate_surrogate_key(['r.user_id']) }} as user_sk
        , ev.event_sk -- Use the event_sk from events_with_venues directly
        
        -- Natural keys for easy identification and joins (crucial for correct grouping)
        , r.event_id 
        
        -- Event information
        , r.group_id
        , r.event_name
        , r.event_status
        , ev.event_start_time
        , ev.venue_id
        
        -- User information
        , r.user_id
        , users.city as user_city
        , users.country as user_country
        
        -- RSVP information
        , r.rsvp_time
        , r.response
        , r.guests
        , r.rsvp_version_number
        
        -- RSVP status flags
        , case when r.response = 'yes' then true else false end as is_attending
        , case when r.response = 'no' then true else false end as is_not_attending
        , case when r.response = 'waitlist' then true else false end as is_waitlisted
    
    from rsvps_latest r
    -- Join directly on event_id (natural key that uniquely identifies each occurrence)
    join events_with_venues ev on r.event_id = ev.event_id
    left join users on r.user_id = users.user_id
)

select * from rsvps_with_keys
