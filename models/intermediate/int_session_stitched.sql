with events as (

    select * from {{ ref('stg_ga4__event') }}

),

sessions as (

    select
        user_pseudo_id,
        ga_session_id,
        ga_session_number,
        min(event_at)                           as session_start_at,
        max(event_at)                           as session_end_at,
        datediff('second', min(event_at), max(event_at)) as session_duration_sec,
        sum(case when event_name = 'page_view' then 1 else 0 end) as page_view_count,
        count(*)                                as event_count,
        sum(engagement_time_msec)               as total_engagement_time_msec,

        -- landing page: first event's page
        min_by(page_location, event_at)         as landing_page,
        -- exit page: last event's page
        max_by(page_location, event_at)         as exit_page,

        -- UTM from first event in session
        min_by(utm_source, event_at)            as utm_source,
        min_by(utm_medium, event_at)            as utm_medium,
        min_by(utm_campaign, event_at)          as utm_campaign,
        min_by(utm_content, event_at)           as utm_content,
        min_by(gclid, event_at)                 as gclid,

        -- geo/device from first event
        min_by(geo_country, event_at)           as geo_country,
        min_by(device_category, event_at)       as device_category,
        min_by(device_browser, event_at)        as device_browser,

        -- user_id (if identified during session)
        max(user_id)                            as user_id,

        -- conversion flag
        max(case when event_name in ('form_submit', 'demo_request', 'content_download')
            then 1 else 0 end)::boolean         as has_conversion,

        'ga4'                                   as source_system

    from events
    group by user_pseudo_id, ga_session_id, ga_session_number

)

select * from sessions
