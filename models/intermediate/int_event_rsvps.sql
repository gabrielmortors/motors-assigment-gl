{{ config(
    materialized = "incremental",
    unique_key = "rsvp_sk",
    incremental_strategy = "merge",
    partition_by = "event_id_clean",
    on_schema_change = 'sync_all_columns'
) }}

with rsvps as (
    select * from {{ ref('stg_event_rsvps') }}
    {% if is_incremental() %}
    -- For incremental runs, only process RSVPs that are new or updated since the last run
    where rsvp_last_modified_at > (select max(rsvp_last_modified_at) from {{ this }})
    {% endif %}
),

events_with_venues as (
    select * from {{ ref('int_events_with_venues') }}
),

users as (
    select * from {{ ref('stg_users') }}
),

-- Deduplicate RSVPs to get only the latest response per user per event
rsvps_latest as (
    select *
    from (
        select
            r.*,
            row_number() over (
                partition by event_id, user_id
                order by rsvp_last_modified_at desc
            ) as rsvp_version_number
        from rsvps r
    )
    where rsvp_version_number = 1
),

rsvps_with_keys as (
    select
        {{ dbt_utils.generate_surrogate_key(['r.user_id', 'r.event_id']) }} as rsvp_sk,
        {{ dbt_utils.generate_surrogate_key(['r.user_id']) }} as user_sk,
        ev.event_sk,
        r.event_id,
        r.event_id_clean,
        ev.group_id,
        ev.event_name,
        ev.event_status,
        ev.event_start_time,
        ev.venue_id,
        r.user_id,
        users.city as user_city,
        users.country as user_country,
        r.rsvp_last_modified_at,
        r.rsvp_response as response,
        r.rsvp_guests as guests,
        r.rsvp_version_number,
        case when r.rsvp_response = 'yes' then true else false end as is_attending,
        case when r.rsvp_response = 'no' then true else false end as is_not_attending,
        case when r.rsvp_response = 'waitlist' then true else false end as is_waitlisted
    from rsvps_latest r
    join events_with_venues ev on r.event_id = ev.event_id
    left join users on r.user_id = users.user_id
)

select * from rsvps_with_keys
