with rsvps as (
    select * from {{ ref('stg_rsvps') }}
),

events as (
    select * from {{ ref('stg_events') }}
),

users as (
    select * from {{ ref('stg_users') }}
),

-- Add row numbers to identify the latest version of each RSVP
rsvp_versions as (
    select 
        *,
        row_number() over (
            partition by user_id, group_id, event_name 
            order by rsvp_time desc
        ) as rsvp_version_number
    from rsvps
),

rsvps_with_keys as (
    select
        -- Surrogate keys
        {{ dbt_utils.generate_surrogate_key(['rsvp_versions.user_id', 'rsvp_versions.group_id', 'rsvp_versions.event_name']) }} as rsvp_sk
        , {{ dbt_utils.generate_surrogate_key(['rsvp_versions.user_id']) }} as user_sk
        , {{ dbt_utils.generate_surrogate_key(['rsvp_versions.group_id', 'rsvp_versions.event_name']) }} as event_sk
        
        -- Event information
        , rsvp_versions.group_id
        , rsvp_versions.event_name
        , rsvp_versions.event_status
        
        -- User information
        , rsvp_versions.user_id
        , users.city as user_city
        , users.country as user_country
        
        -- RSVP information
        , rsvp_versions.rsvp_time
        , rsvp_versions.response
        , rsvp_versions.guests
        , rsvp_versions.rsvp_version_number
        
        -- RSVP response flags for easier filtering
        , case when rsvp_versions.response = 'yes' then true else false end as is_attending
        , case when rsvp_versions.response = 'no' then true else false end as is_not_attending
        , case when rsvp_versions.response = 'waitlist' then true else false end as is_waitlisted
    from rsvp_versions
    left join users
        on rsvp_versions.user_id = users.user_id
)

select * from rsvps_with_keys
