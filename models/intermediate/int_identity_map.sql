with ga4_identified as (

    select
        user_pseudo_id,
        user_id as ga4_user_id,
        event_at
    from {{ ref('stg_ga4__event') }}
    where user_id is not null
      and trim(user_id) != ''

),

-- take the earliest email mapping per user_pseudo_id
first_identification as (

    select
        user_pseudo_id,
        ga4_user_id                             as email,
        min(event_at)                           as first_identified_at
    from ga4_identified
    group by user_pseudo_id, ga4_user_id

),

-- handle multi-email per pseudo_id: earliest wins
deduplicated as (

    select
        user_pseudo_id,
        email,
        first_identified_at,
        row_number() over (
            partition by user_pseudo_id
            order by first_identified_at
        ) as rn
    from first_identification

),

identity_map as (

    select
        d.user_pseudo_id,
        d.email,
        d.first_identified_at,
        p.person_id
    from deduplicated d
    left join {{ ref('int_person_merged') }} p
        on lower(trim(d.email)) = lower(trim(p.email))
    where d.rn = 1

)

select * from identity_map
