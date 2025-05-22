{{config(
    materialized = 'table'
)}}

-- Grain: one row per RSVP (latest version of each RSVP)

with event_rsvps as (
    select * from {{ ref('int_event_rsvps') }}
)

, events_with_venues as (
    select * from {{ ref('int_events_with_venues') }}
)

, dim_users as (
    select * from {{ ref('dim_users') }}
)

, fact_events as (
    select * from {{ ref('fact_events') }}
)

-- Create the final fact table with RSVP-level granularity
, final as (
    select
        -- Surrogate keys for dimension relationships
        er.rsvp_sk
        , er.user_sk
        , er.event_sk
        , ev.venue_sk
        
        -- Natural keys
        , er.event_id -- Include natural event ID for proper join relationships
        , er.user_id
        , er.group_id
        , er.event_name
        
        -- RSVP metadata
        , er.rsvp_last_modified_at as rsvp_time
        , date(er.rsvp_last_modified_at) as rsvp_date
        , er.response
        , er.guests
        , er.rsvp_version_number
        
        -- RSVP status flags
        , er.is_attending
        , er.is_not_attending
        , er.is_waitlisted
        
        -- Event metadata
        , ev.event_status
        , ev.event_start_time
        , date(ev.event_start_time) as event_date
        , ev.is_past
        , ev.is_upcoming
        , ev.is_cancelled
        
        -- Calculated metrics
        , datediff(minute, er.rsvp_last_modified_at, ev.event_start_time) as minutes_from_rsvp_to_event
        , round(datediff(minute, er.rsvp_last_modified_at, ev.event_start_time) / 60.0, 1) as hours_from_rsvp_to_event
        , round(datediff(minute, er.rsvp_last_modified_at, ev.event_start_time) / 1440.0, 1) as days_from_rsvp_to_event
        
        , case
            when date(er.rsvp_last_modified_at) = date(ev.event_start_time) then true
            else false
        end as is_same_day_rsvp
        
        , case
            when datediff(day, er.rsvp_last_modified_at, ev.event_start_time) <= 1 then 'Last Minute'
            when datediff(day, er.rsvp_last_modified_at, ev.event_start_time) <= 7 then 'Within Week'
            else 'Early'
        end as rsvp_timing_category
        
        -- Total attendance including guests
        , case
            when er.is_attending then er.guests + 1
            else 0
        end as total_attendance
        
    from event_rsvps er
    inner join events_with_venues ev on er.event_id = ev.event_id  -- Join on natural key
    inner join dim_users du on er.user_sk = du.user_sk
    
    -- Keep only the latest version of each RSVP for the fact table
    where er.rsvp_version_number = 1
)

select * from final
