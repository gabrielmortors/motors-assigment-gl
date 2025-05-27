{{ config(
    unique_key='topic_key',
    on_schema_change='sync_all_columns'
) }}

with raw_data as (
    select * from {{ ref('raw_groups') }}
),

-- Extract topics from array for analysis
group_topics as (
    select
        group_id
        , exploded as topic
        , {{ dbt_utils.generate_surrogate_key(['group_id', 'exploded']) }} as topic_key
    from 
        raw_data
        LATERAL VIEW EXPLODE(topics) exploded_table AS exploded
)

select 
    group_id,
    topic,
    topic_key
from group_topics
