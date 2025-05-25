{{config(
    materialized = 'table'
)}}

with events_with_venues as (
    select * from {{ ref('int_events_with_venues') }}
),

dim_venues as (
    select * from {{ ref('dim_venues') }}
),

-- Calculate daily activity metrics for each venue
daily_venue_metrics as (
    select
        venue_id,
        date(event_start_time) as activity_date,
        count(distinct event_sk) as daily_events,
        count(distinct group_id) as daily_groups,
        sum(case when is_cancelled then 1 else 0 end) as cancelled_events
    from events_with_venues
    where venue_id is not null
      and event_start_time is not null -- Ensure activity_date can be derived
    group by 1, 2
),

-- Calculate first and last event dates for milestone tracking
venue_milestones as (
    select
        venue_id,
        min(date(event_start_time)) as first_event_date,
        max(date(event_start_time)) as last_event_date
    from events_with_venues
    where venue_id is not null
    group by 1
),

final as (
    select
        v.venue_sk,
        dvm.activity_date,
        v.venue_id,
        v.venue_name,
        
        -- Daily metrics
        dvm.daily_events,
        dvm.daily_groups,
        dvm.cancelled_events,
        
        -- Milestone flags
        case when dvm.activity_date = vm.first_event_date then true else false end as is_first_event_date,
        case when dvm.activity_date = vm.last_event_date then true else false end as is_last_event_date,
        
        -- Time-relative metrics
        datediff(day, vm.first_event_date, dvm.activity_date) as days_since_first_event,
        datediff(day, vm.first_event_date, vm.last_event_date) as venue_active_days
        
    from daily_venue_metrics dvm
    inner join dim_venues v on dvm.venue_id = v.venue_id
    left join venue_milestones vm on dvm.venue_id = vm.venue_id
    where dvm.daily_events > 0
)

select * from final
