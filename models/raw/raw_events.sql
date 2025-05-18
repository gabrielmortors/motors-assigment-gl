with source as (
    select * from {{ source('raw_data', 'events') }}
),

renamed as (
    select
        -- Event identifiers
        group_id::STRING
        , name::STRING as event_name
        
        -- Event details
        , description::STRING as event_description
        -- Convert epoch timestamps to proper timestamps
        , from_unixtime(created/1000)::TIMESTAMP as event_created_at
        , from_unixtime(time/1000)::TIMESTAMP as event_start_time
        , duration::BIGINT as event_duration_seconds
        , rsvp_limit::INT as rsvp_limit
        , venue_id::STRING
        , status::STRING as event_status
        
        -- RSVP details are kept as array structure for staging to process
        , rsvps
    from source
)

select * from renamed
