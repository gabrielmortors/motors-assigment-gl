-- models/pbi/pbi_fact_venue_activity.sql
-- This model prepares fact_venue_activity for Power BI by casting surrogate keys to string type.

select
    {{ dbt_utils.star(from=ref('fact_venue_activity'), except=['venue_sk']) }}
    , cast(venue_sk as string) as venue_sk
from {{ ref('fact_venue_activity') }}
