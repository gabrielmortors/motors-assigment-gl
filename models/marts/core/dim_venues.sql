{{config(
    materialized = 'table'
)}}

{% set popularity_high_threshold = 10 %}
{% set popularity_medium_threshold = 5 %}
{% set multi_group_threshold = 3 %}

with events_with_venues as (
    select * from {{ ref('int_events_with_venues') }}
),

-- Extract unique venue data (descriptive attributes)
venue_data as (
    select distinct
        venue_sk,
        venue_id,
        venue_name,
        venue_city,
        venue_country,
        venue_lat,
        venue_lon
    from events_with_venues
    where venue_id is not null
),

-- Calculate latest snapshot metrics
-- Note: These will be updated when the model runs but don't support time-series analysis
venue_metrics as (
    select
        venue_id,
        count(distinct event_sk) as total_events,
        count(distinct group_id) as total_groups_hosted
    from events_with_venues
    where venue_id is not null
    group by 1
),

final as (
    select
        v.venue_sk,
        v.venue_id,
        v.venue_name,
        v.venue_city,
        v.venue_country,
        v.venue_lat,
        v.venue_lon,
        
        -- Current snapshot counts (as of last model run)
        m.total_events,
        m.total_groups_hosted,
        
        -- Derived classification attributes for filtering
        case 
            when m.total_events > {{ popularity_high_threshold }} then 'High'
            when m.total_events > {{ popularity_medium_threshold }} then 'Medium' 
            else 'Low' 
        end as venue_popularity,
        
        case
            when m.total_groups_hosted > {{ multi_group_threshold }} then true
            else false
        end as is_multi_group_venue
    from venue_data v
    inner join venue_metrics m on v.venue_id = m.venue_id
)

select * from final
