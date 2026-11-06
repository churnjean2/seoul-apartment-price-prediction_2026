-- Purpose : Are missing approval dates truly blank in the source, or failed casts?
-- Result  : 2026-11-06 22:39 — 12,986 blank in the source; 6,181 in YYYY-MM-DD (parsed);
--           29 malformed values such as '1985-05-' (become NULL via try_strptime).
-- Decision: Missing dates are a source gap, not a cast bug. Use the trade's
--           construction year (built_year) for building age instead.
-- SQL     : LENGTH() on raw text reveals format differences before casting.

select
    length(사용승인일자)   as len,
    사용승인일자 is null   as is_blank,
    count(*)               as n,
    min(사용승인일자)      as example
from {{ source('raw', 'building_register') }}
group by all
order by n desc