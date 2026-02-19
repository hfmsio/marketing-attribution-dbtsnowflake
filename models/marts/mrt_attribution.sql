with eligible_touchpoints as (

    select
        t.touchpoint_key,
        t.person_id,
        t.campaign_key,
        t.channel_id,
        ch.channel_name,
        t.touchpoint_at,
        t.touchpoint_type,
        o.opportunity_id,
        o.opportunity_name,
        o.deal_amount,
        o.opportunity_stage,
        o.is_won,
        o.is_closed,
        o.created_at as opportunity_created_at
    from {{ ref('unf_touchpoint') }} t
    join {{ ref('unf_person') }} p
        on t.person_id = p.person_id
        and p.is_current
    join {{ ref('unf_opportunity') }} o
        on p.account_id = o.account_id
    left join {{ ref('unf_channel') }} ch
        on t.channel_id = ch.channel_id
    where t.touchpoint_at < o.created_at
      and t.touchpoint_at >= dateadd('day', -180, o.created_at)

),

weighted as (

    select
        *,
        count(*) over (partition by opportunity_id) as total_touchpoints,
        'linear'                                as attribution_model
    from eligible_touchpoints

)

select
    touchpoint_key,
    opportunity_id,
    person_id,
    campaign_key,
    channel_id,
    channel_name,
    touchpoint_at,
    touchpoint_type,
    attribution_model,
    1.0 / total_touchpoints                     as attribution_weight,
    deal_amount / nullif(total_touchpoints, 0)  as attributed_revenue_amount,
    deal_amount,
    opportunity_stage,
    is_won,
    is_closed,
    datediff('day', touchpoint_at, opportunity_created_at) as days_to_opportunity,
    current_timestamp()::timestamp_ntz                         as loaded_at

from weighted
