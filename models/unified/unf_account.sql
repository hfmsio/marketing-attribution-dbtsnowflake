with accounts as (

    select * from {{ ref('stg_salesforce__account') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['account_id']) }} as account_key,
    account_id,
    account_name,
    industry,
    employee_count,
    annual_revenue_amount,
    account_type,
    source_system,
    current_timestamp()::timestamp_ntz                         as loaded_at

from accounts
