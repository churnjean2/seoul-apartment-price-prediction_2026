-- One row per dong + main lot number. Used as a second-pass match when a
-- trade's exact parcel (main + sub lot) is not in the register.
-- A building is assigned only when the main lot holds exactly one
-- multi-family record, so neighbouring parcels are never guessed.

select
    bjd_code || '-' || main_lot_no                      as main_lot_key,
    bjd_code,
    main_lot_no,
    sum(case when main_use = '공동주택' then 1 else 0 end)  as n_multi_family,
    case
        when sum(case when main_use = '공동주택' then 1 else 0 end) = 1
        then max(case when main_use = '공동주택' then register_id end)
    end                                                 as register_id
from {{ ref('int_building_register_coded') }}
where bjd_code is not null
group by bjd_code, main_lot_no