with source as (

    select * from {{ source('raw_salesforce', 'raw_salesforce__opportunity') }}
    where IsDeleted = 'false'

),

renamed as (

    select
        Id                                          as opportunity_id,
        AccountId                                   as account_id,
        Name                                        as opportunity_name,
        StageName                                   as opportunity_stage,
        cast(Amount as decimal(18, 2))              as deal_amount,
        cast(CloseDate as date)                     as close_date,
        cast(Probability as decimal(5, 2))          as probability,
        cast(IsClosed as boolean)                   as is_closed,
        cast(IsWon as boolean)                      as is_won,
        LeadSource                                  as lead_source,
        OwnerId                                     as owner_id,
        cast(CreatedDate as timestamp_ntz)          as created_at,
        cast(LastModifiedDate as timestamp_ntz)     as updated_at,
        'salesforce'                                as source_system

    from source

)

select * from renamed
