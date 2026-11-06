-- Purpose : Why was construction-year agreement only 54.6% for exact matches (a07)?
--           Check how many matched buildings actually have an approval date.
-- Result  : 2026-11-06 22:32 — 93,557 of 167,630 matched trades (55.8%) have an approval
--           date; among those, 97.8% agree with the trade's construction year.
-- Decision: The exact match is reliable. The low a07 baseline came from missing dates
--           counted as disagreements, not from wrong matches.
--           Follow-ups: find out why 44% of dates are missing (a09), and re-run a07
--           on dated rows only so the main-lot rejection uses a fair baseline.
-- SQL     : COUNT(col) counts only non-null values, while COUNT(*) counts all rows —
--           dividing by COUNT(col) gives a rate among rows that have the value.

select 
    count(*) as n, count(b.approval_date) as has_date, 
    round(100.0 * count(*) filter (where year(b.approval_date) = t.built_year) / count(b.approval_date), 
    1) as same_year_pct_of_dated from {{ ref('int_apartment_trades_matched') }} t 
join {{ ref('int_building_register_coded') }} b using (register_id) 
where t.match_status = 'matched'