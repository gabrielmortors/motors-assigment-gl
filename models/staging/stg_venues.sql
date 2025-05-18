with raw_data as (
    select * from {{ ref('raw_venues') }}
),

venues as (
    select
        venue_id
        , venue_name
        , city
        , country
        , lat
        , lon
    from raw_data
)

select * from venues
