{{ config(
    materialized = "incremental",
    unique_key    = "venue_id",
    incremental_strategy = "merge",
    on_schema_change='sync_all_columns'
) }}

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

{% if is_incremental() %}
  -- No specific timestamp filter here, merge will compare all records
  -- based on venue_id. If a true updated_at timestamp becomes available
  -- in raw_venues, it can be added here for efficiency.
{% endif %}
