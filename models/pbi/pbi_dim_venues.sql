-- models/pbi/pbi_dim_venues.sql
-- This model prepares dim_venues for Power BI by casting surrogate keys to string type.

select
    {{ dbt_utils.star(from=ref('dim_venues'), except=['venue_sk']) }}
    , cast(venue_sk as string) as venue_sk
from {{ ref('dim_venues') }}
