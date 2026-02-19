-- For each opportunity + model, weights should sum to ~1.0
select
    opportunity_id,
    attribution_model,
    sum(attribution_weight) as total_weight
from {{ ref('mrt_attribution') }}
group by 1, 2
having abs(total_weight - 1.0) > 0.01
