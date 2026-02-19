with source as (

    select * from {{ source('raw_salesforce', 'raw_salesforce__lead') }}
    where IsDeleted = 'false'

),

renamed as (

    select
        Id                                          as lead_id,
        FirstName                                   as first_name,
        LastName                                    as last_name,
        lower(trim(Email))                          as email,
        Company                                     as company_name,
        Title                                       as title,
        Phone                                       as phone,
        Status                                      as lead_status,
        LeadSource                                  as lead_source,
        cast(IsConverted as boolean)                as is_converted,
        ConvertedContactId                          as converted_contact_id,
        ConvertedAccountId                          as converted_account_id,
        ConvertedOpportunityId                      as converted_opportunity_id,
        cast(ConvertedDate as date)                 as converted_date,
        OwnerId                                     as owner_id,
        cast(CreatedDate as timestamp_ntz)          as created_at,
        cast(LastModifiedDate as timestamp_ntz)     as updated_at,
        'salesforce'                                as source_system

    from source

)

select * from renamed
