-- Purpose : Validate the main-lot second pass. KEPT AS A LESSON: this check is circular.
-- Result  : 2026-11-06 22:12 — 149,220 of 149,220 agree (100%).
-- Why it proves nothing: an exactly matched parcel sits inside its main lot, so if the
--   main lot holds one multi-family record it must be the same building. Replaced by a07.
-- SQL     : Same pattern as a02 — the pattern was fine, the question was wrong.

select
    count(*) as n,
    count(*) filter (where t.register_id = ml.register_id) as agree
from {{ ref('int_apartment_trades_matched') }} as t
join {{ ref('int_register_main_lots') }} as ml using (bjd_code, main_lot_no)
where t.match_status = 'matched'
  and ml.register_id is not null