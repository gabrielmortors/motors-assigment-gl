-- models/pbi/pbi_dim_users.sql
-- This model prepares dim_users for Power BI by casting surrogate keys to string type.

select
    {{ dbt_utils.star(from=ref('dim_users'), except=['user_sk']) }}
    , cast(user_sk as string) as user_sk
from {{ ref('dim_users') }}
