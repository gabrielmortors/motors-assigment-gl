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

-- DIAGNOSTIC QUERY 2: Is event_id duplicated in the fact table after our fix?
-- Should return 0 rows if our event_sk solution works correctly
select 
    event_id
    , count(*) rows
from {{ ref('fact_events') }}
group by event_id
having rows > 1
order by rows desc
limit 10;

-- SANITY CHECK: Check for duplicate RSVP counts that indicate duplicated data
-- Should return empty if overcounting is fixed, or only show rows with dup_rows ≤ 5
select 
    attending_count
    , not_attending_count
    , count(*) dup_rows
from {{ ref('fact_events') }}
group by 1, 2
having dup_rows > 5
order by dup_rows desc;
