with source as (

    select * from {{ source('raw_google_ads', 'raw_google_ads__campaign_stats') }}

),

renamed as (

    select
        cast(customer_id as varchar)                as customer_id,
        cast(date as date)                          as report_date,
        cast(campaign_id as varchar)                as campaign_id,
        cast(clicks as integer)                     as clicks,
        cast(impressions as integer)                as impressions,
        cast(cost_micros as decimal(18, 2)) / 1000000 as spend_amount,
        cast(conversions as decimal(18, 6))         as conversions_count,
        cast(conversions_value as decimal(18, 6))   as conversions_value_amount,
        'google_ads'                                as source_system

    from source

)

select * from renamed
