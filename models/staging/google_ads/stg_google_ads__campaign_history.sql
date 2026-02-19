with source as (

    select * from {{ source('raw_google_ads', 'raw_google_ads__campaign_history') }}

),

renamed as (

    select
        cast(id as varchar)                         as campaign_id,
        cast(updated_at as timestamp_ntz)           as updated_at,
        cast(customer_id as varchar)                as customer_id,
        name                                        as campaign_name,
        status                                      as campaign_status,
        advertising_channel_type                    as channel_type,
        cast(start_date as date)                    as start_date,
        cast(end_date as date)                      as end_date,
        'google_ads'                                as source_system

    from source

)

select * from renamed
