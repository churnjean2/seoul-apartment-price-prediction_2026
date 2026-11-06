-- Purpose : For unmatched trades, does the main lot number exist in the register?
-- Result  : 2026-11-06 22:07 — 71% no main lot at all; 29% main lot exists (sub lot differs).
-- Decision: Try a main-lot second pass (later rejected, see a07).
-- SQL     : CTEs (WITH u AS ...); LEFT JOIN to test whether a match exists.

with u as (
    select * from {{ ref('int_apartment_trades_matched') }}
    where match_status = 'lot_not_in_register'
),

m as (
    select distinct bjd_code, main_lot_no
    from {{ ref('int_register_lots') }}
)

select
    m.bjd_code is not null as main_lot_exists,
    count(*) as trades,
    count(distinct u.bjd_code || u.main_lot_no || u.sub_lot_no) as lots
from u
left join m using (bjd_code, main_lot_no)
group by all