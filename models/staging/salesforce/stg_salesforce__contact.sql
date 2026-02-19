with source as (

    select * from {{ source('raw_salesforce', 'raw_salesforce__contact') }}
    where IsDeleted = 'false'

),

renamed as (

    select
        Id                                      as contact_id,
        AccountId                               as account_id,
        FirstName                               as first_name,
        LastName                                as last_name,
        lower(trim(Email))                      as email,
        Title                                   as title,
        Phone                                   as phone,
        LeadSource                              as lead_source,
        OwnerId                                 as owner_id,
        cast(CreatedDate as timestamp_ntz)      as created_at,
        cast(LastModifiedDate as timestamp_ntz) as updated_at,
        'salesforce'                            as source_system

    from source

)

select * from renamed
