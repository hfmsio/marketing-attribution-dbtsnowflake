with google as (

    select
        campaign_id,
        report_date,
        sum(clicks)                             as clicks,
        sum(impressions)                        as impressions,
        sum(spend_amount)                       as spend_amount,
        sum(conversions_count)                  as conversions_count,
        sum(conversions_value_amount)           as conversions_value_amount,
        'google_ads'                            as platform

    from {{ ref('stg_google_ads__campaign_stats') }}
    group by campaign_id, report_date

)

-- In the full implementation, LinkedIn and Meta CTEs would be unioned here
-- following the same schema. Each ad platform normalizes its metrics
-- (e.g., LinkedIn lacks conversions_value, Meta reports at ad-level not campaign)
-- into this consistent shape before the union.

select * from google
