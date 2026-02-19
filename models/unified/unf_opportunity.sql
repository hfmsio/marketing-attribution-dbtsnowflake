with opportunities as (

    select * from {{ ref('stg_salesforce__opportunity') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['opportunity_id']) }} as opportunity_key,
    opportunity_id,
    account_id,
    opportunity_name,
    opportunity_stage,
    deal_amount,
    close_date,
    probability,
    is_closed,
    is_won,
    lead_source,
    created_at,
    source_system,
    current_timestamp()::timestamp_ntz                         as loaded_at

from opportunities
