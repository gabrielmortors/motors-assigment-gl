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
        , {{ to_timestamp_from_unix('created') }} as event_created_at
        , {{ to_timestamp_from_unix('time') }} as event_start_time
        , {{ convert_milliseconds_to_seconds('duration') }}::BIGINT as event_duration_seconds
        , rsvp_limit::INT as rsvp_limit
        , venue_id::STRING
        , status::STRING as event_status
        
        -- RSVP details are kept as array structure for staging to process
        , rsvps
    from source
)

select * from renamed
