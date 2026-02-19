with utm_combos as (

    select distinct
        utm_source,
        utm_medium
    from {{ ref('stg_ga4__event') }}
    where utm_source is not null
       or utm_medium is not null

),

channels as (

    select
        utm_source,
        utm_medium,
        case
            when utm_medium in ('cpc', 'ppc') then 'Paid Search'
            when utm_medium = 'paid_social' then 'Paid Social'
            when utm_medium = 'email' then 'Email'
            when utm_medium = 'organic' then 'Organic Search'
            when utm_medium = 'referral' then 'Referral'
            when utm_medium = 'social' then 'Organic Social'
            else 'Other'
        end as channel_name,
        case
            when utm_medium in ('cpc', 'ppc', 'paid_social') then 'Paid'
            when utm_medium in ('email') then 'Owned'
            else 'Earned'
        end as channel_group

    from utm_combos

),

with_direct as (

    select * from channels
    union all
    select
        null    as utm_source,
        null    as utm_medium,
        'Direct' as channel_name,
        'Direct' as channel_group

)

select
    {{ dbt_utils.generate_surrogate_key(["coalesce(utm_source, '__null__')", "coalesce(utm_medium, '__null__')"]) }} as channel_key,
    coalesce(lower(utm_source), 'none')
        || '__' || coalesce(lower(utm_medium), 'none')
                                                as channel_id,
    channel_name,
    utm_source,
    utm_medium,
    channel_group,
    current_timestamp()::timestamp_ntz                         as loaded_at

from with_direct
