with raw_data as (
    select * from {{ ref('raw_groups') }}
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

select * from group_topics
