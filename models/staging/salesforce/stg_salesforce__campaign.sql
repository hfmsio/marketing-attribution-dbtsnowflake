with source as (

    select * from {{ source('raw_salesforce', 'raw_salesforce__campaign') }}
    where IsDeleted = 'false'

),

renamed as (

    select
        Id                                          as campaign_id,
        Name                                        as campaign_name,
        Type                                        as campaign_type,
        Status                                      as campaign_status,
        cast(StartDate as date)                     as start_date,
        cast(EndDate as date)                       as end_date,
        cast(IsActive as boolean)                   as is_active,
        cast(BudgetedCost as decimal(18, 2))        as budgeted_cost_amount,
        cast(ActualCost as decimal(18, 2))          as actual_cost_amount,
        cast(CreatedDate as timestamp_ntz)          as created_at,
        'salesforce'                                as source_system

    from source

)

select * from renamed
