with source as (
    select * from {{ source('raw_data', 'groups') }}
),

renamed as (
    select
        -- Group identifiers
        group_id::STRING
        , name::STRING as group_name
        
        -- Location information
        , city::STRING
        , lat::DOUBLE
        , lon::DOUBLE
        
        -- Group details
        , from_unixtime(created/1000)::TIMESTAMP as created_at
        , description::STRING as group_description 
        , link::STRING as group_link
        
        -- Topics array
        , topics
    from source
)

select * from renamed
