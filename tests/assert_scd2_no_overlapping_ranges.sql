-- Validates SCD2 structural invariants on unf_person:
-- 1. No overlapping valid_from/valid_to windows for any person.
-- 2. Every person_id has exactly one row with is_current = true.
-- 3. No valid_to precedes valid_from within the same row.
-- Note: with the current stub (one row per person), check #1 is vacuous
-- but checks #2 and #3 are meaningful. All three activate when real
-- snapshots replace the stub.

-- Check 1: overlapping ranges (activates with real SCD2)
select
    a.person_id,
    'overlapping_ranges' as violation_type
from {{ ref('unf_person') }} a
join {{ ref('unf_person') }} b
    on a.person_id = b.person_id
    and a.person_key != b.person_key
    and a.valid_from < coalesce(b.valid_to, '9999-12-31'::timestamp_ntz)
    and b.valid_from < coalesce(a.valid_to, '9999-12-31'::timestamp_ntz)

union all

-- Check 2: persons with != 1 current row
select
    person_id,
    'wrong_current_count' as violation_type
from {{ ref('unf_person') }}
group by person_id
having sum(case when is_current then 1 else 0 end) != 1

union all

-- Check 3: valid_to before valid_from
select
    person_id,
    'invalid_date_range' as violation_type
from {{ ref('unf_person') }}
where valid_to is not null
  and valid_to < valid_from
