-- One row per parcel (dong code + lot numbers) in the building register,
-- summarising what is registered there. Collapsing to one row per parcel
-- prevents the trade -> building join from duplicating trades.

select
    bjd_code,
    main_lot_no,
    sub_lot_no,
    count(*)                                            as n_records,
    count(*) filter (where main_use = '공동주택')        as n_multi_family,
    -- Only assign a building when the parcel has exactly one multi-family record
    case
        when count(*) filter (where main_use = '공동주택') = 1
        then any_value(register_id) filter (where main_use = '공동주택')
    end                                                 as register_id
from {{ ref('int_building_register_coded') }}
where bjd_code is not null
group by bjd_code, main_lot_no, sub_lot_no