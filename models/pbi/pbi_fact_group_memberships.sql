-- models/pbi/pbi_fact_group_memberships.sql
-- This model prepares fact_group_memberships for Power BI by casting surrogate keys to string type.

select
    {{ dbt_utils.star(from=ref('fact_group_memberships'), except=['membership_sk', 'user_sk', 'group_sk']) }}
    , cast(membership_sk as string) as membership_sk
    , cast(user_sk as string) as user_sk
    , cast(group_sk as string) as group_sk
from {{ ref('fact_group_memberships') }}
