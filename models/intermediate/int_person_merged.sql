with contacts as (

    select
        contact_id                              as person_id,
        account_id,
        first_name,
        last_name,
        email,
        title,
        lead_source,
        created_at,
        updated_at,
        'contact'                               as record_type,
        source_system
    from {{ ref('stg_salesforce__contact') }}

),

unconverted_leads as (

    select
        lead_id                                 as person_id,
        null                                    as account_id,
        first_name,
        last_name,
        email,
        title,
        lead_source,
        lead_status,
        created_at,
        updated_at,
        'lead'                                  as record_type,
        source_system
    from {{ ref('stg_salesforce__lead') }}
    where not is_converted

),

lead_metadata as (

    select
        converted_contact_id,
        lead_id                                 as original_lead_id,
        lead_status,
        is_converted,
        converted_date,
        converted_account_id,
        converted_opportunity_id
    from {{ ref('stg_salesforce__lead') }}
    where is_converted
    -- Guard: one contact can be the target of multiple lead conversions
    qualify row_number() over (
        partition by converted_contact_id
        order by converted_date desc
    ) = 1

),

merged as (

    select
        c.person_id,
        c.account_id,
        c.first_name,
        c.last_name,
        c.email,
        c.title,
        c.lead_source,
        lm.lead_status                            as person_status,
        coalesce(lm.is_converted, false)          as is_converted,
        lm.converted_date,
        lm.original_lead_id,
        c.created_at,
        c.updated_at,
        c.source_system
    from contacts c
    left join lead_metadata lm
        on c.person_id = lm.converted_contact_id

    union all

    select
        ul.person_id,
        ul.account_id,
        ul.first_name,
        ul.last_name,
        ul.email,
        ul.title,
        ul.lead_source,
        ul.lead_status                           as person_status,
        false                                    as is_converted,
        null                                     as converted_date,
        ul.person_id                             as original_lead_id,
        ul.created_at,
        ul.updated_at,
        ul.source_system
    from unconverted_leads ul

)

select * from merged
