{{config(
    materialized = 'table'
)}}

-- Grain: one row per event (latest version of each event)

with events_with_venues as (
    select * from {{ ref('int_events_with_venues') }}
)

, event_rsvps as (
    select * from {{ ref('int_event_rsvps') }}
)

, dim_groups as (
    select * from {{ ref('dim_groups') }}
)

-- Aggregate RSVP metrics by event
, event_attendance as (
    select
        event_sk
        , count(rsvp_sk) as total_responses -- All RSVP responses (yes, no, waitlist)
        , sum(case when is_attending then 1 else 0 end) as attending_count -- Only Yes responses
        , sum(case when is_not_attending then 1 else 0 end) as not_attending_count -- Only No responses
        , sum(case when is_waitlisted then 1 else 0 end) as waitlist_count -- Only waitlist responses
        , sum(case when is_attending then guests else 0 end) as total_guests -- Additional guests
        , count(distinct user_id) as unique_respondents -- Unique people who responded
    from event_rsvps
    group by 1
)

-- Create the final fact table with event-level granularity
, final as (
    select
        -- Surrogate keys for dimension relationships
        ev.event_sk
        , ev.venue_sk
        , dg.group_sk
        
        -- Natural keys
        , ev.group_id
        , ev.event_name
        , ev.venue_id
        
        -- Event metadata
        , ev.event_status
        , ev.event_created_at
        , ev.event_start_time
        , date(ev.event_start_time) as event_date
        , ev.event_version_number
        
        -- Event status flags
        , ev.is_suggested
        , ev.is_proposed
        , ev.is_cancelled
        , ev.is_past
        , ev.is_upcoming
        
        -- Capacity metrics
        , ev.rsvp_limit
        
        -- RSVP metrics
        , coalesce(ea.total_responses, 0) as total_responses -- All RSVP responses (yes, no, waitlist)
        , coalesce(ea.attending_count, 0) as attending_count -- Yes responses only
        , coalesce(ea.not_attending_count, 0) as not_attending_count -- No responses only
        , coalesce(ea.waitlist_count, 0) as waitlist_count -- Waitlist responses only
        , coalesce(ea.total_guests, 0) as total_guests -- Additional guests
        , coalesce(ea.unique_respondents, 0) as unique_respondents -- Unique respondents
        
        -- Calculated metrics
        , coalesce(ea.attending_count, 0) + coalesce(ea.total_guests, 0) as total_expected_attendance -- Actually attending
        
        -- Calculate what percentage of the capacity limit is filled
        , case
            when ev.rsvp_limit is not null and ev.rsvp_limit > 0 then
                round(
                    (coalesce(ea.attending_count, 0) + coalesce(ea.total_guests, 0))::float / ev.rsvp_limit::float * 100, 
                    1
                )
            else null
        end as percent_capacity_filled
        
        -- Time metrics between event creation and start
        , datediff(minute, ev.event_created_at, ev.event_start_time) as minutes_from_creation_to_event
        , round(datediff(minute, ev.event_created_at, ev.event_start_time) / 60.0, 1) as hours_from_creation_to_event
        , round(datediff(minute, ev.event_created_at, ev.event_start_time) / 1440.0, 1) as days_from_creation_to_event
        
        -- Event duration metrics (now properly converted from milliseconds at staging layer)
        , ev.event_duration_seconds
        , round(ev.event_duration_seconds / 60.0, 1) as event_duration_minutes
        , round(ev.event_duration_seconds / 3600.0, 1) as event_duration_hours
        , round(ev.event_duration_seconds / 86400.0, 1) as event_duration_days
        
    from events_with_venues ev
    left join event_attendance ea on ev.event_sk = ea.event_sk
    left join dim_groups dg on ev.group_id = dg.group_id
    
    -- Keep only the latest version of each event for the fact table
    where ev.event_version_number = 1
)

select * from final
