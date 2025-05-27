-- DIAGNOSTIC QUERY 1: How many distinct start-dates share each event_id?
-- This shows us which recurring events have many occurrences sharing the same event_id
select 
    event_id
    , count(distinct event_start_time) as distinct_dates
from {{ ref('stg_events') }}
group by event_id
having distinct_dates > 1
order by distinct_dates desc
limit 10;

-- DIAGNOSTIC QUERY 2: Does any natural event_id appear in fact_event_attendance more than once?
-- This would indicate an issue if event_sk is meant to be unique per event_id in the context of attendance facts.
-- Should return 0 rows if each natural event_id corresponds to at most one entry in fact_event_attendance.
select
    de.event_id
    , count(fea.event_sk) as fact_rows_per_event_id
from {{ ref('fact_event_attendance') }} fea
join {{ ref('dim_events') }} de on fea.event_sk = de.event_sk
group by de.event_id
having count(fea.event_sk) > 1
order by fact_rows_per_event_id desc
limit 10;

-- SANITY CHECK: Check for duplicate RSVP counts that indicate duplicated data
-- Should return empty if overcounting is fixed, or only show rows with dup_rows ≤ 5
select 
    attending_count
    , not_attending_count
    , count(*) dup_rows
from {{ ref('fact_event_attendance') }}
group by 1, 2
having dup_rows > 5
order by dup_rows desc;
