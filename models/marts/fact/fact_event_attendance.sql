{{ config(materialized='table') }}

-- 1. Attendance aggregated on event_sk
with event_attendance as (
    select
        event_sk
        , count(*) as total_responses
        , sum(case when response = 'yes' then 1 else 0 end) as attending_count
        , sum(case when response = 'no' then 1 else 0 end) as not_attending_count
        , sum(case when response = 'waitlist' then 1 else 0 end) as waitlist_count
        , sum(guests) as total_guests -- This sums all guests from all RSVPs for the event_sk
        , count(distinct user_id) as unique_respondents
    from {{ ref('int_event_rsvps') }} -- Assumes int_event_rsvps provides the latest response per user per event_sk
    group by event_sk
)

-- 2. Select necessary fields from dim_events
, dim_events_source as (
    select
        event_sk
        , event_start_date_id
        , rsvp_limit -- Needed for percent_capacity_filled calculation
    from {{ ref('dim_events') }}
)

-- 3. Final join, bringing event details and aggregated RSVP data together
, final_fact_data as (
    select
        de.event_sk
        , de.event_start_date_id as attendance_date_id -- Use event_start_date_id as the primary date for this fact
        , de.rsvp_limit
        , coalesce(ea.total_responses, 0) as total_responses
        , coalesce(ea.attending_count, 0) as attending_count
        , coalesce(ea.not_attending_count, 0) as not_attending_count
        , coalesce(ea.waitlist_count, 0) as waitlist_count
        , coalesce(ea.total_guests, 0) as total_guests
        , coalesce(ea.unique_respondents, 0) as unique_respondents
    from dim_events_source de
    left join event_attendance ea using (event_sk)
)

-- Final selection, adding calculated metrics
select
    f.event_sk
    , f.attendance_date_id
    , f.total_responses
    , f.attending_count
    , f.not_attending_count
    , f.waitlist_count
    , f.total_guests
    , f.unique_respondents
    , (f.attending_count + f.total_guests) as total_expected_attendance
    , case
        when f.rsvp_limit is not null and f.rsvp_limit > 0 then
            round(
                ((f.attending_count + f.total_guests)::float / f.rsvp_limit::float) * 100,
                1
            )
        else null
    end as percent_capacity_filled
from final_fact_data f
