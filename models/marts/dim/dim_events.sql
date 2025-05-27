{{ config(
    materialized='table',
    unique_key='event_sk'
) }}

with source_events as (
    select *
    from {{ ref('int_events_with_venues') }} -- This model already provides the latest version of event details
)

-- Final selection with surrogate key generation and date key casting
select
    event_sk,
    event_id,
    group_id, -- We can later decide if this should be group_sk
    venue_id, -- We can later decide if this should be venue_sk
    event_name,
    event_description,
    event_created_at,
    event_start_time,
    event_duration_seconds,
    rsvp_limit,
    event_status,
    event_version_number,
    is_suggested,
    is_proposed,
    is_cancelled,
    is_past,
    is_upcoming,
    event_start_time::date as event_start_date_id,
    event_created_at::date as event_created_date_id
from source_events
