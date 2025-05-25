-- models/pbi/pbi_dim_date.sql
-- This model prepares dim_date for Power BI.
-- Typically, dim_date does not have surrogate keys that need casting to string,
-- but it's included in the PBI layer for completeness.

select *
from {{ ref('dim_date') }}
