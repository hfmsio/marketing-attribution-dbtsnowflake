-- In production this reads from snp_person (dbt snapshot) for SCD2.
-- For the implemented slice, we derive directly from int_person_merged
-- and treat current state as the only version.

with person as (

    select * from {{ ref('int_person_merged') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['person_id', 'created_at']) }} as person_key,
    person_id,
    account_id,
    email,
    first_name,
    last_name,
    title,
    person_status,
    lead_source,
    is_converted,
    converted_date                              as converted_at,
    source_system,
    created_at                                  as valid_from,
    cast(null as timestamp_ntz)                 as valid_to,
    true                                        as is_current,
    current_timestamp()::timestamp_ntz           as loaded_at

from person
