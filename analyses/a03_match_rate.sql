-- Purpose : What share of apartment trades matched a building?
-- Result  : 2026-11-06 22:05 — matched 84.6%, lot_not_in_register 14.7%.
-- Decision: Investigate the 14.7% before accepting it (a04, a05).
-- SQL     : Window function SUM(COUNT(*)) OVER () gives the grand total for a percentage.

select
    match_status,
    count(*) as n,
    round(100.0 * count(*) / sum(count(*)) over (), 1) as pct
from {{ ref('int_apartment_trades_matched') }}
group by all
order by n desc