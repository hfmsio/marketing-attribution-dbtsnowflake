with web_touchpoints as (

    select
        e.user_pseudo_id,
        im.person_id,
        e.event_at                              as touchpoint_at,
        e.event_name                            as touchpoint_type,
        'ga4'                                   as touchpoint_source,
        s.ga_session_id                         as session_id,
        e.page_location                         as page_url,
        e.utm_source,
        e.utm_medium,
        e.utm_campaign,
        case when e.event_name in ('form_submit', 'demo_request', 'content_download')
            then true else false
        end                                     as is_conversion
    from {{ ref('stg_ga4__event') }} e
    left join {{ ref('int_identity_map') }} im
        on e.user_pseudo_id = im.user_pseudo_id
    left join {{ ref('int_session_stitched') }} s
        on e.user_pseudo_id = s.user_pseudo_id
        and e.ga_session_id = s.ga_session_id
    where e.event_name in ('page_view', 'form_submit', 'demo_request', 'content_download')

),

crm_touchpoints as (

    select
        null                                    as user_pseudo_id,
        coalesce(
            nullif(cm.contact_id, ''),
            l.converted_contact_id,
            cm.lead_id
        )                                       as person_id,
        coalesce(cm.first_responded_at, cm.created_at) as touchpoint_at,
        case
            when lower(c.campaign_type) = 'webinar' then 'event_attended'
            when lower(c.campaign_type) = 'email' then 'email_responded'
            else 'campaign_response'
        end                                     as touchpoint_type,
        'salesforce'                            as touchpoint_source,
        null                                    as session_id,
        null                                    as page_url,
        null                                    as utm_source,
        null                                    as utm_medium,
        cm.campaign_id                          as utm_campaign,
        cm.has_responded                        as is_conversion
    from {{ ref('stg_salesforce__campaign_member') }} cm
    left join {{ ref('stg_salesforce__campaign') }} c
        on cm.campaign_id = c.campaign_id
    left join {{ ref('stg_salesforce__lead') }} l
        on cm.lead_id = l.lead_id

),

all_touchpoints as (

    select * from web_touchpoints
    union all
    select * from crm_touchpoints

),

enriched as (

    select
        t.*,
        p.account_id,
        ch.channel_key,
        ch.channel_id                           as ch_channel_id,
        ch.channel_name,
        camp.campaign_key
    from all_touchpoints t
    left join {{ ref('int_person_merged') }} p
        on t.person_id = p.person_id
    left join {{ ref('unf_channel') }} ch
        on coalesce(t.utm_medium, 'none') = coalesce(ch.utm_medium, 'none')
        and coalesce(t.utm_source, 'none') = coalesce(ch.utm_source, 'none')
    left join {{ ref('unf_campaign') }} camp
        on (
            -- GA4: match utm_campaign slug to campaign name via normalization
            t.touchpoint_source = 'ga4'
            and lower(replace(camp.campaign_name, ' ', '-')) = lower(t.utm_campaign)
            and camp.platform != 'salesforce'
        )
        or (
            -- CRM: direct campaign_id match
            t.touchpoint_source = 'salesforce'
            and camp.campaign_id = t.utm_campaign
            and camp.platform = 'salesforce'
        )
    -- Guard against fan-out: keep at most one campaign match per touchpoint
    qualify row_number() over (
        partition by t.person_id, t.touchpoint_at, t.touchpoint_type,
                     coalesce(t.page_url, ''), t.touchpoint_source,
                     coalesce(t.utm_campaign, '')
        order by camp.campaign_key nulls last
    ) = 1

),

sequenced as (

    select
        {{ dbt_utils.generate_surrogate_key(["person_id", "touchpoint_at", "touchpoint_type", "coalesce(page_url, '__null__')", "touchpoint_source", "coalesce(utm_campaign, '__null__')"]) }} as touchpoint_key,
        person_id,
        campaign_key,
        ch_channel_id                           as channel_id,
        account_id,
        touchpoint_at,
        touchpoint_type,
        touchpoint_source,
        is_conversion,
        session_id,
        page_url,
        row_number() over (
            partition by person_id
            order by touchpoint_at
        )                                       as touchpoint_sequence,
        datediff('day',
            lag(touchpoint_at) over (partition by person_id order by touchpoint_at),
            touchpoint_at
        )                                       as days_since_previous_touchpoint
    from enriched
    where person_id is not null

)

select
    touchpoint_key,
    person_id,
    campaign_key,
    channel_id,
    account_id,
    touchpoint_at,
    touchpoint_type,
    touchpoint_source,
    is_conversion,
    session_id,
    page_url,
    touchpoint_sequence,
    days_since_previous_touchpoint,
    current_timestamp()::timestamp_ntz                         as loaded_at

from sequenced
