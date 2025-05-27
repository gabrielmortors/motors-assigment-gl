-- models/pbi/pbi_fact_events.sql
-- This model prepares fact_event_attendance for Power BI by casting surrogate keys to string type.
-- Casts event_sk. venue_sk is in dim_events and should be handled by a corresponding pbi_dim_events model.

select
    {{ dbt_utils.star(from=ref('fact_event_attendance'), except=['event_sk']) }}
    , cast(event_sk as string) as event_sk
from {{ ref('fact_event_attendance') }}
