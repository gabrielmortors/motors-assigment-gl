with raw_data as (
    select * from {{ ref('raw_events') }}
)

-- Extract base event details without the nested structures
, events as (
    select
        group_id
        , event_name
        , event_description
        , event_created_at
        , event_start_time
        -- Convert duration from milliseconds to seconds (divide by 1000) and round to whole seconds
        , case 
            when event_duration_seconds is null then null
            else round(event_duration_seconds / 1000, 0)
          end as event_duration_seconds
        , rsvp_limit
        , venue_id
        , event_status
        -- Create a truly unique event_id that distinguishes each occurrence
        , CONCAT(group_id, '-', 
                REGEXP_REPLACE(event_name, '[\s]+', '-'), '-', 
                DATE_FORMAT(event_start_time, 'yyyy-MM-dd-HH-mm')) as event_id
    from raw_data
)

select * from events
