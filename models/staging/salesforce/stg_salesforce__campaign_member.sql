with source as (

    select * from {{ source('raw_salesforce', 'raw_salesforce__campaign_member') }}
    where IsDeleted = 'false'

),

renamed as (

    select
        Id                                          as campaign_member_id,
        CampaignId                                  as campaign_id,
        LeadId                                      as lead_id,
        ContactId                                   as contact_id,
        Status                                      as member_status,
        cast(HasResponded as boolean)               as has_responded,
        cast(FirstRespondedDate as timestamp_ntz)   as first_responded_at,
        cast(CreatedDate as timestamp_ntz)          as created_at,
        'salesforce'                                as source_system

    from source

)

select * from renamed
