with raw_data as (
    select * from {{ ref('raw_groups') }}
),

groups as (
    select
        group_id
        , group_name
        , city
        , lat
        , lon
        , created_at
        , group_description
        , group_link
    from raw_data
),

-- Extract topics from array for analysis
group_topics as (
    select
        group_id
        , exploded as topic
    from 
        raw_data
        LATERAL VIEW EXPLODE(topics) exploded_table AS exploded
)

select * from groups
