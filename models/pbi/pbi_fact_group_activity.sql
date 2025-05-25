-- models/pbi/pbi_fact_group_activity.sql
-- This model prepares fact_group_activity for Power BI by casting surrogate keys to string type.

select
    {{ dbt_utils.star(from=ref('fact_group_activity'), except=['group_sk']) }}
    , cast(group_sk as string) as group_sk
from {{ ref('fact_group_activity') }}
