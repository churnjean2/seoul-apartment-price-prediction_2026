-- Purpose : Independent check — does the trade's construction year match the
--           building's approval year? Compares exact matches with main-lot candidates.
-- Result  : 2026-11-06 22:19 — raw: same year 54.6% (exact) vs 7.5% (main lot).
--           2026-11-06 22:38 — dated rows only: 97.8% (exact) vs 11.0% (main lot).
--           The raw baseline was low because missing approval dates counted as
--           disagreements (see a08).
-- Decision: Reject the main-lot second pass (status 'main_lot_only', not used).
--           Confirmed on a fair baseline: about 9 in 10 candidates were a different building.
-- SQL     : AVG(CASE WHEN ... THEN 1 ELSE 0 END) turns a condition into a percentage.

with candidates as (
    select
        t.match_status,
        t.built_year,
        coalesce(t.register_id, ml.register_id) as candidate_register_id
    from {{ ref('int_apartment_trades_matched') }} as t
    left join {{ ref('int_register_main_lots') }} as ml using (bjd_code, main_lot_no)
    where t.match_status in ('matched', 'main_lot_only')
)

select
    c.match_status,
    count(*) as n,
    round(100.0 * avg(case when year(b.approval_date) = c.built_year then 1 else 0 end), 1)
        as same_year_pct,
    round(100.0 * avg(case when abs(year(b.approval_date) - c.built_year) <= 1 then 1 else 0 end), 1)
        as within_1yr_pct,
    count(b.approval_date) as has_date,
    round(100.0 * count(*) filter (where year(b.approval_date) = c.built_year)
          / count(b.approval_date), 1) as same_year_pct_of_dated
from candidates as c
join {{ ref('int_building_register_coded') }} as b
    on b.register_id = c.candidate_register_id
group by all