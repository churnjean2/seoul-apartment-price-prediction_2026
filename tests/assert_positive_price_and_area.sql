-- Singular test: returns the rows that break the rule; any row means failure.
-- A zero or negative price or area is a data error, not an outlier,
-- so it is a fixed rule that belongs in dbt rather than in the model pipeline.

select *
from {{ ref('mart_training_trades') }}
where price_10k_krw <= 0
   or floor_area_m2 <= 0