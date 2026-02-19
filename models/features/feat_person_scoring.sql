-- Point-in-time correct feature table for lead scoring.
-- Grain: 1 row per person per as_of_date.
-- All features use strictly backward-looking windows (< as_of_date).

{{ config(
    materialized='incremental',
    unique_key=['person_id', 'as_of_date'],
    incremental_strategy='delete+insert',
    on_schema_change='fail'
) }}

with min_date as (

    {% if is_incremental() %}
    select min(as_of_date)::date as start_date from {{ this }}
    {% else %}
    select min(touchpoint_at)::date as start_date
    from {{ ref('unf_touchpoint') }}
    {% endif %}

),

date_spine as (

    select
        dateadd('day', seq4() * 7, md.start_date) as as_of_date
    from table(generator(rowcount => 1000)) g
    cross join min_date md
    where dateadd('day', seq4() * 7, md.start_date) <= current_date()

    {% if is_incremental() %}
        and dateadd('day', seq4() * 7, md.start_date) > (
            select max(as_of_date) from {{ this }}
        )
    {% endif %}

),

persons as (

    select person_id, lead_source, person_status
    from {{ ref('unf_person') }}
    where is_current

),

touchpoints as (

    select * from {{ ref('unf_touchpoint') }}

),

features as (

    select
        p.person_id,
        d.as_of_date,
        p.person_status,
        p.lead_source,

        -- recency
        datediff('day', min(t.touchpoint_at), d.as_of_date) as days_since_first_touch,
        datediff('day', max(t.touchpoint_at), d.as_of_date) as days_since_last_touch,

        -- volume (windowed)
        sum(case when t.touchpoint_at >= dateadd('day', -7, d.as_of_date)
                  and t.touchpoint_at < d.as_of_date then 1 else 0 end)
            as touchpoint_count_7d,
        sum(case when t.touchpoint_at >= dateadd('day', -30, d.as_of_date)
                  and t.touchpoint_at < d.as_of_date then 1 else 0 end)
            as touchpoint_count_30d,
        sum(case when t.touchpoint_at < d.as_of_date then 1 else 0 end)
            as touchpoint_count_all,

        -- diversity
        count(distinct case when t.touchpoint_at >= dateadd('day', -30, d.as_of_date)
                             and t.touchpoint_at < d.as_of_date
                        then t.channel_id end)
            as distinct_channel_count_30d,

        -- type-specific counts
        sum(case when t.touchpoint_type = 'page_view'
                  and t.touchpoint_at >= dateadd('day', -7, d.as_of_date)
                  and t.touchpoint_at < d.as_of_date then 1 else 0 end)
            as page_view_count_7d,
        sum(case when t.touchpoint_type = 'page_view'
                  and t.touchpoint_at >= dateadd('day', -30, d.as_of_date)
                  and t.touchpoint_at < d.as_of_date then 1 else 0 end)
            as page_view_count_30d,
        sum(case when t.touchpoint_type = 'form_submit'
                  and t.touchpoint_at < d.as_of_date then 1 else 0 end)
            as form_submit_count_all,
        sum(case when t.touchpoint_type = 'content_download'
                  and t.touchpoint_at < d.as_of_date then 1 else 0 end)
            as content_download_count_all,
        max(case when t.touchpoint_type = 'demo_request'
                  and t.touchpoint_at < d.as_of_date then 1 else 0 end)::boolean
            as has_demo_request,

        -- session count (distinct sessions in last 30d)
        count(distinct case when t.touchpoint_at >= dateadd('day', -30, d.as_of_date)
                             and t.touchpoint_at < d.as_of_date
                        then t.session_id end)
            as session_count_30d,

        -- engagement cadence: average days between touchpoints
        case when count(case when t.touchpoint_at < d.as_of_date then 1 end) > 1
            then datediff('day', min(t.touchpoint_at), max(t.touchpoint_at))
                 / nullif(count(case when t.touchpoint_at < d.as_of_date then 1 end) - 1, 0)
            else null
        end as avg_days_between_touchpoints

    from persons p
    cross join date_spine d
    left join touchpoints t
        on p.person_id = t.person_id
        and t.touchpoint_at < d.as_of_date
    group by p.person_id, d.as_of_date, p.person_status, p.lead_source

)

select
    person_id,
    as_of_date,
    person_status,
    lead_source,
    days_since_first_touch,
    days_since_last_touch,
    touchpoint_count_7d,
    touchpoint_count_30d,
    touchpoint_count_all,
    distinct_channel_count_30d,
    page_view_count_7d,
    page_view_count_30d,
    form_submit_count_all,
    content_download_count_all,
    has_demo_request,
    session_count_30d,
    avg_days_between_touchpoints,
    current_timestamp()::timestamp_ntz                         as inserted_at,
    current_timestamp()::timestamp_ntz                         as updated_at

from features
where touchpoint_count_all > 0
