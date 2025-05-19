with raw_data as (
    select * from {{ ref('raw_events') }}
)

-- Unnest the array of RSVP objects into separate rows
, flattened as (
    select 
        group_id
        , event_name
        , event_status
        , exploded.user_id as user_id
        , from_unixtime(exploded.when/1000) as rsvp_time
        , exploded.response as response
        , exploded.guests as guests
    from 
        raw_data
        LATERAL VIEW EXPLODE(rsvps) exploded_table AS exploded
)

-- Extract the event_date from the rsvp data for more precise matching
, rsvps_with_date as (
    select
        f.*
        -- Extract a date from the RSVP time to help match with the correct event occurrence
        , date(f.rsvp_time) as rsvp_date
    from flattened f
)

-- Join with stg_events to get the proper event_id
, events as (
    select 
        *
        -- Extract the event date for joining
        , date(event_start_time) as event_date 
    from {{ ref('stg_events') }}
)

-- Match RSVPs to their specific event occurrences using date-based logic
select
    r.group_id
    , r.event_name
    , r.event_status
    , r.user_id
    , r.rsvp_time
    , r.response
    , r.guests
    , e.event_id
    -- Add clear indicator this is a properly date-matched RSVP
    , case 
        when e.event_id is not null then true
        else false
      end as is_matched_to_event
from rsvps_with_date r
-- Match each RSVP to the most appropriate event occurrence based on date proximity
join events e on 
    r.group_id = e.group_id 
    and r.event_name = e.event_name 
    -- RSVPs should happen before the event starts (or at most 1 day after for late RSVPs)
    and r.rsvp_date <= date_add(e.event_date, 1)
    -- Qualify by taking the closest event to the RSVP date
qualify row_number() over (
    partition by r.group_id, r.event_name, r.user_id, r.rsvp_time
    order by abs(datediff(r.rsvp_date, e.event_date)) -- take the closest event by date
) = 1
