-- Purpose : How many trades survive each filter on the way to the training table?
-- Result: 198,179 apartment trades -> 153,884 training rows (77.6% kept).
--         Lost 30,549 at the register match (small complexes with no
--         multi-family record), 9,084 cancelled, 219 presale rights,
--         4,443 direct deals.
-- Decision: Keep every filter. Each step removes rows that do not reflect
--           a normal market price, and the funnel documents exactly why.
-- SQL     : Several COUNT(*) FILTER columns in one pass build a funnel.

with t as (
    select * from {{ ref('int_apartment_trades_matched') }}
)

select
    count(*) as all_apartment_trades,
    count(*) filter (where match_status = 'matched') as matched,
    count(*) filter (where match_status = 'matched'
                       and is_cancelled is not true) as not_cancelled,
    count(*) filter (where match_status = 'matched'
                       and is_cancelled is not true
                       and is_presale_right is not true) as not_presale,
    count(*) filter (where match_status = 'matched'
                       and is_cancelled is not true
                       and is_presale_right is not true
                       and is_direct_deal is not true) as training_rows
from t