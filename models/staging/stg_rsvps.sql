with raw_data as (
    select * from {{ ref('raw_events') }}
),

-- Unnest the array of RSVP objects into separate rows
flattened as (
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

select
    group_id
    , event_name
    , event_status
    , user_id
    , rsvp_time
    , response
    , guests
from flattened
