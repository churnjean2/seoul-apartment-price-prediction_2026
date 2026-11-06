-- Apartment trades joined to the building register at parcel level.
-- Every trade is kept; match_status explains why a trade did or did not match.

with trades as (
    select
        -- The source has no transaction ID, so create a stable surrogate key
        row_number() over (
            order by contract_date, bjd_code, main_lot_no, sub_lot_no,
                     floor, price_10k_krw, floor_area_m2
        ) as trade_id,
        *
    from {{ ref('stg_transactions') }}
    where building_use = '아파트'
),

lots as (
    select * from {{ ref('int_register_lots') }},
),

main_lots as (
    select * from {{ ref('int_register_main_lots') }}
)

select
    t.*,
    -- Fall back to the main-lot match only when the exact parcel is absent
    coalesce(
        l.register_id,  -- main-lot fallback rejected: only 7.5% construction-year agreement
    ) as register_id,
    case
        when t.main_lot_no is null                         then 'no_lot_number'
        when l.bjd_code is not null and l.n_multi_family = 1 then 'matched'
        when l.bjd_code is not null and l.n_multi_family = 0 then 'no_multi_family_record'
        when l.bjd_code is not null                        then 'multiple_multi_family_records'
        when ml.n_multi_family = 1                         then 'main_lot_only'  -- candidate, not used
        else 'lot_not_in_register'  -- no usable match at parcel or main-lot level
    end as match_status
from trades as t
left join lots as l
    on  t.bjd_code    = l.bjd_code
    and t.main_lot_no = l.main_lot_no
    and t.sub_lot_no  = l.sub_lot_no
left join main_lots as ml
    on  t.bjd_code    = ml.bjd_code
    and t.main_lot_no = ml.main_lot_no