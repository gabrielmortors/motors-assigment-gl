with source as (
    select * from {{ source('raw_data', 'venues') }}
),

renamed as (
    select
        -- Venue identifiers
        venue_id::STRING
        , name::STRING as venue_name
        
        -- Location information
        , city::STRING
        , country::STRING
        , lat::DOUBLE
        , lon::DOUBLE
    from source
)

select * from renamed
