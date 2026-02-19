-- Unifies CRM campaigns and ad platform campaigns into a single entity.
-- CRM-to-ad mapping would use UTM matching in production;
-- for the implemented slice, we keep them as separate rows with platform column.

with crm_campaigns as (

    select
        campaign_id,
        campaign_name,
        campaign_type,
        campaign_status,
        null                                    as objective,
        start_date,
        end_date,
        budgeted_cost_amount                    as budget_amount,
        'salesforce'                            as platform
    from {{ ref('stg_salesforce__campaign') }}

),

google_campaigns as (

    select
        campaign_id,
        campaign_name,
        'Paid Search'                           as campaign_type,
        campaign_status,
        null                                    as objective,
        start_date,
        end_date,
        cast(null as decimal(18,2))             as budget_amount,
        'google_ads'                            as platform
    from {{ ref('stg_google_ads__campaign_history') }}
    qualify row_number() over (partition by campaign_id order by updated_at desc) = 1

),

-- In the full implementation, LinkedIn and Meta CTEs would follow here
-- with the same output schema, handling platform-specific differences:
-- - LinkedIn: has 'objective' field, uses daily_budget_amount
-- - Meta: uses started_at/stopped_at instead of start_date/end_date

unioned as (

    select * from crm_campaigns
    union all
    select * from google_campaigns

)

select
    {{ dbt_utils.generate_surrogate_key(['campaign_id', 'platform']) }} as campaign_key,
    campaign_id,
    campaign_name,
    campaign_type,
    platform,
    objective,
    campaign_status,
    start_date,
    end_date,
    budget_amount,
    current_timestamp()::timestamp_ntz                         as loaded_at

from unioned
