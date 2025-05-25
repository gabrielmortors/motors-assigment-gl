-- models/pbi/pbi_fact_events.sql
-- This model prepares fact_events for Power BI by casting surrogate keys to string type.
-- Casts event_sk and venue_sk. group_sk was removed as it's not in the source.

select
    {{ dbt_utils.star(from=ref('fact_events'), except=['event_sk', 'venue_sk']) }}
    , cast(event_sk as string) as event_sk
    , cast(venue_sk as string) as venue_sk
from {{ ref('fact_events') }}
