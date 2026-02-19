with ad_spend as (

    select
        campaign_id,
        platform,
        report_date                             as spend_date,
        impressions                             as impressions_count,
        clicks                                  as clicks_count,
        spend_amount,
        conversions_count,
        conversions_value_amount
    from {{ ref('int_ad_platforms_unioned') }}

),

with_campaign_key as (

    select
        {{ dbt_utils.generate_surrogate_key(['campaign_id', 'platform']) }} as campaign_key,
        platform,
        spend_date,
        impressions_count,
        clicks_count,
        spend_amount,
        conversions_count,
        conversions_value_amount
    from ad_spend

)

select
    campaign_key,
    platform,
    spend_date,
    impressions_count,
    clicks_count,
    spend_amount,
    conversions_count,
    conversions_value_amount,
    current_timestamp()::timestamp_ntz                         as loaded_at

from with_campaign_key
