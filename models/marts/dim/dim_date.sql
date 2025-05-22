{{config(
    materialized = 'table'
)}}

{# Get dynamic date range from events data using our custom macro #}
{% set date_range = get_date_range() %}

-- Generate a date dimension using the dbt_date package and dynamic date range
with date_spine as (
    {{ dbt_date.get_date_dimension(date_range.start_date, date_range.end_date) }}
),

-- Select key date attributes for our dimension and calculate additional flags
dim_date as (
    select
        -- Primary date keys
        date_day as date_id,
        date_day,
        
        -- Basic date components 
        day_of_week,
        day_of_week_name,
        day_of_month,
        month_of_year,
        month_name,
        quarter_of_year,
        year_number,
        
        -- Additional date components
        day_of_year,
        week_of_year,

        -- Calculate boolean flags
        case when day_of_week in (1, 7) then true else false end as is_weekend,
        case when day_of_month = 1 then true else false end as is_month_start,
        case when day_of_month = day(last_day(date_day)) then true else false end as is_month_end,
        case when day_of_month = 1 and month_of_year in (1, 4, 7, 10) then true else false end as is_quarter_start,
        case when day_of_month = day(last_day(date_day)) and month_of_year in (3, 6, 9, 12) then true else false end as is_quarter_end,
        case when day_of_month = 1 and month_of_year = 1 then true else false end as is_year_start,
        case when day_of_month = 31 and month_of_year = 12 then true else false end as is_year_end
    from
        date_spine
)

select * from dim_date
order by date_day
