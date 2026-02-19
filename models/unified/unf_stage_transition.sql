-- Derives lifecycle stage transitions from lead conversion events.
-- In production, this would also track status field changes via SCD2.

with persons as (

    select
        person_id,
        lead_source,
        person_status,
        is_converted,
        converted_at,
        valid_from
    from {{ ref('unf_person') }}
    where is_current

),

transitions as (

    -- Lead created (entry into funnel)
    select
        person_id,
        'None'                                  as from_stage,
        'New'                                   as to_stage,
        valid_from                              as transitioned_at
    from persons

    union all

    -- Lead to MQL (for converted leads: approximate midpoint)
    select
        person_id,
        'New'                                   as from_stage,
        'MQL'                                   as to_stage,
        dateadd('day',
            datediff('day', valid_from, converted_at::timestamp_ntz) / 2,
            valid_from
        )                                       as transitioned_at
    from persons
    where is_converted

    union all

    -- Lead to MQL (for non-converted leads with MQL+ status)
    select
        person_id,
        'New'                                   as from_stage,
        'MQL'                                   as to_stage,
        -- no conversion date available; use created_at as best proxy
        valid_from                              as transitioned_at
    from persons
    where person_status in ('MQL', 'Qualified')
      and not is_converted

    union all

    -- MQL to Qualified/SQL (for converted leads)
    select
        person_id,
        'MQL'                                   as from_stage,
        'Qualified'                             as to_stage,
        converted_at::timestamp_ntz             as transitioned_at
    from persons
    where is_converted

    union all

    -- MQL to Qualified/SQL (for non-converted leads at Qualified status)
    select
        person_id,
        'MQL'                                   as from_stage,
        'Qualified'                             as to_stage,
        valid_from                              as transitioned_at
    from persons
    where person_status = 'Qualified'
      and not is_converted

)

select
    {{ dbt_utils.generate_surrogate_key(['person_id', 'from_stage', 'to_stage', 'transitioned_at']) }} as transition_key,
    person_id,
    from_stage,
    to_stage,
    transitioned_at,
    current_timestamp()::timestamp_ntz                         as loaded_at

from transitions
where transitioned_at is not null
