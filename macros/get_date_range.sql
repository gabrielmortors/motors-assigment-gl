{% macro get_date_range() %}

{# This macro calculates the optimal date range for the date dimension based on events data #}
{% set query %}
    with event_dates as (
        select
            min(event_created_at) as min_created_date,
            min(event_start_time) as min_start_date,
            max(event_created_at) as max_created_date,
            max(event_start_time) as max_start_date
        from {{ ref('stg_events') }}
    )
    
    select
        -- Get the earliest date between created_at and start_time
        least(min_created_date, min_start_date)::date as start_date,
        
        -- Get the latest date between created_at and start_time and add 1 year
        dateadd(year, 1, greatest(max_created_date, max_start_date))::date as end_date
    from event_dates
{% endset %}

{% set results = run_query(query) %}

{% if execute %}
    {% set start_date = results.columns[0].values()[0] %}
    {% set end_date = results.columns[1].values()[0] %}
{% else %}
    {# Default values for parsing #}
    {% set start_date = '2015-01-01' %}
    {% set end_date = '2025-01-01' %}
{% endif %}

{# Return a dictionary with the dates #}
{{ return({'start_date': start_date, 'end_date': end_date}) }}

{% endmacro %}
