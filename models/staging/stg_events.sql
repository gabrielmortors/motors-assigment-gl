{{ config(
    materialized = "incremental",
    unique_key    = "event_id",
    incremental_strategy = "merge",
    on_schema_change='sync_all_columns',
    partition_by = "event_partition_date"
) }}

with raw_data as (
    select * from {{ ref('raw_events') }}
)

-- Add a row number to handle potential exact duplicates in source data
, raw_data_with_row_num as (
    select
        *,
        ROW_NUMBER() OVER (PARTITION BY 
            COALESCE(CAST(group_id AS STRING), 'gid_null'),
            COALESCE(event_name, 'ename_null'),
            COALESCE(CAST(event_start_time AS STRING), 'etime_null'),
            COALESCE(event_description, 'edesc_null')
            ORDER BY event_created_at -- or any other deterministic column
        ) as rn
    from raw_data
)

-- Extract base event details and construct event_id using dbt_utils.generate_surrogate_key
, events_with_surrogate_id as (
    select
        group_id
        , event_name
        , event_description
        , event_created_at
        , event_start_time
        , event_duration_seconds
        , rsvp_limit
        , venue_id
        , event_status
        , rsvps  -- Pass through the rsvps array
        , 
          {{ 
            dbt_utils.generate_surrogate_key(
              [
                'COALESCE(CAST(group_id AS STRING), "gid_null")',
                'COALESCE(event_name, "ename_null")',
                'COALESCE(CAST(event_start_time AS STRING), "etime_null")',
                'COALESCE(event_description, "edesc_null")',
                'CAST(rn AS STRING)'
              ]
            ) 
          }} 
        as generated_event_id
    from raw_data_with_row_num
)

-- Final select with event_id (as unique_key) and cleaned event_id (for partitioning)
, final_events as (
    select
        group_id
        , event_name
        , event_description
        , event_created_at
        , event_start_time
        , event_duration_seconds
        , rsvp_limit
        , venue_id
        , event_status
        , rsvps -- Pass through rsvps
        , generated_event_id as event_id -- This is the unique_key for the model
        -- Clean the generated_event_id. Since it's an MD5 hash, it's already quite clean,
        -- but we apply regexp_replace to ensure it fits typical column naming conventions if needed elsewhere.
        , regexp_replace(generated_event_id, '[^a-zA-Z0-9_]', '_') as event_id_clean
        , date(event_start_time) as event_partition_date  -- Partition key based on event start date to handle recurring events
    from events_with_surrogate_id
)

{% if is_incremental() %}
  -- this filter will only be applied on an incremental run
  -- and will optimize the amount of data scanned from the raw_events model
  select * from final_events where event_created_at > (select max(event_created_at) from {{ this }})
{% else %}
  select * from final_events
{% endif %}
