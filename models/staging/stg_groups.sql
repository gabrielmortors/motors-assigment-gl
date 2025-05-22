{{ config(
    materialized = "incremental",
    unique_key    = "group_id",
    incremental_strategy = "merge",
    on_schema_change='sync_all_columns'
) }}

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
{% if is_incremental() %}
  -- this filter will only be applied on an incremental run
  where created_at > (select max(created_at) from {{ this }})
{% endif %}
