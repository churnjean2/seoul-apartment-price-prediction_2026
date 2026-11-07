-- Purpose : How many trades survive each filter on the way to the training table?
-- Result  :
-- Decision:
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