-- models/pbi/pbi_fact_rsvps.sql
-- This model prepares fact_rsvps for Power BI by casting surrogate keys to string type.
-- Assumes rsvp_sk, user_sk, event_sk are the relevant surrogate keys in fact_rsvps.
-- Please verify and add/remove SKs as necessary.

select
    {{ dbt_utils.star(from=ref('fact_rsvps'), except=['rsvp_sk', 'user_sk', 'event_sk']) }}
    , cast(rsvp_sk as string) as rsvp_sk
    , cast(user_sk as string) as user_sk
    , cast(event_sk as string) as event_sk
from {{ ref('fact_rsvps') }}
