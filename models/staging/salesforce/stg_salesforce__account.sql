with source as (

    select * from {{ source('raw_salesforce', 'raw_salesforce__account') }}
    where IsDeleted = 'false'

),

renamed as (

    select
        Id                                      as account_id,
        Name                                    as account_name,
        Type                                    as account_type,
        Industry                                as industry,
        cast(NumberOfEmployees as integer)       as employee_count,
        cast(AnnualRevenue as decimal(18, 2))   as annual_revenue_amount,
        Website                                 as website,
        BillingCountry                          as billing_country,
        OwnerId                                 as owner_id,
        cast(CreatedDate as timestamp_ntz)      as created_at,
        cast(LastModifiedDate as timestamp_ntz) as updated_at,
        'salesforce'                            as source_system

    from source

)

select * from renamed
