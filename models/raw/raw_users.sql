with source as (
    select * from {{ source('raw_data', 'users') }}
),

renamed as (
    select
        -- User identifiers
        user_id::STRING
        
        -- Location information
        , city::STRING
        , country::STRING
        , hometown::STRING
        
        -- Memberships array containing joined timestamps and group_ids
        , memberships
    from source
)

select * from renamed
