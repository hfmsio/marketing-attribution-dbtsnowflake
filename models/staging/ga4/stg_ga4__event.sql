with source as (

    select * from {{ source('raw_ga4', 'raw_ga4__event') }}

),

renamed as (

    select
        to_date(cast(event_date as varchar), 'YYYYMMDD') as event_date,
        -- Seeds use ISO strings; production GA4 BigQuery exports store
        -- microseconds and would need: to_timestamp_ntz(event_timestamp, 6)
        cast(event_timestamp as timestamp_ntz)      as event_at,
        event_name,
        user_pseudo_id,
        user_id,
        cast(ga_session_id as varchar)              as ga_session_id,
        cast(ga_session_number as integer)          as ga_session_number,
        page_location,
        page_title,
        page_referrer,
        cast(engagement_time_msec as integer)       as engagement_time_msec,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content,
        gclid,
        geo_country,
        geo_region,
        geo_city,
        device_category,
        device_browser,
        platform                                    as device_platform,
        'ga4'                                       as source_system

    from source

)

select * from renamed
