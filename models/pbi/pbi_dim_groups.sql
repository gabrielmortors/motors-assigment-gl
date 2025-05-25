-- models/pbi/pbi_dim_groups.sql
-- This model prepares dim_groups for Power BI by casting surrogate keys to string type.

select
    {{ dbt_utils.star(from=ref('dim_groups'), except=['group_sk']) }}
    , cast(group_sk as string) as group_sk
from {{ ref('dim_groups') }}
