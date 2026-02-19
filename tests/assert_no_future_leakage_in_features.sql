-- Verify that key feature columns match actual backward-looking counts.
-- Any mismatch = future data leakage in the ML feature table.
-- Checks: touchpoint_count_30d, form_submit_count_all, has_demo_request.
with actual_counts as (

    select
        t.person_id,
        f.as_of_date,
        count(*)                                    as actual_touchpoint_count_30d,
        sum(case when t.touchpoint_type = 'form_submit' then 1 else 0 end)
                                                    as actual_form_submit_count_all,
        max(case when t.touchpoint_type = 'demo_request' then 1 else 0 end)::boolean
                                                    as actual_has_demo_request
    from {{ ref('feat_person_scoring') }} f
    join {{ ref('unf_touchpoint') }} t
        on f.person_id = t.person_id
        and t.touchpoint_at >= dateadd('day', -30, f.as_of_date)
        and t.touchpoint_at < f.as_of_date
    group by 1, 2

),

-- All-time form submits and demo requests (not windowed to 30d)
actual_alltime as (

    select
        t.person_id,
        f.as_of_date,
        sum(case when t.touchpoint_type = 'form_submit' then 1 else 0 end)
                                                    as actual_form_submit_count_all,
        max(case when t.touchpoint_type = 'demo_request' then 1 else 0 end)::boolean
                                                    as actual_has_demo_request
    from {{ ref('feat_person_scoring') }} f
    join {{ ref('unf_touchpoint') }} t
        on f.person_id = t.person_id
        and t.touchpoint_at < f.as_of_date
    group by 1, 2

)

select
    f.person_id,
    f.as_of_date,
    'touchpoint_count_30d' as failed_column,
    f.touchpoint_count_30d as reported,
    coalesce(a.actual_touchpoint_count_30d, 0) as actual
from {{ ref('feat_person_scoring') }} f
left join actual_counts a
    on f.person_id = a.person_id
    and f.as_of_date = a.as_of_date
where f.touchpoint_count_30d != coalesce(a.actual_touchpoint_count_30d, 0)

union all

select
    f.person_id,
    f.as_of_date,
    'form_submit_count_all' as failed_column,
    f.form_submit_count_all as reported,
    coalesce(at.actual_form_submit_count_all, 0) as actual
from {{ ref('feat_person_scoring') }} f
left join actual_alltime at
    on f.person_id = at.person_id
    and f.as_of_date = at.as_of_date
where f.form_submit_count_all != coalesce(at.actual_form_submit_count_all, 0)

union all

select
    f.person_id,
    f.as_of_date,
    'has_demo_request' as failed_column,
    f.has_demo_request::int as reported,
    coalesce(at.actual_has_demo_request, false)::int as actual
from {{ ref('feat_person_scoring') }} f
left join actual_alltime at
    on f.person_id = at.person_id
    and f.as_of_date = at.as_of_date
where f.has_demo_request != coalesce(at.actual_has_demo_request, false)
