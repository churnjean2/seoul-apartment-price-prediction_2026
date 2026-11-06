-- One row per reported trade (all building types).
-- Renames columns to English, casts types, and flags rows that
-- later models will exclude. No rows are removed here.

with source as (
    select * from {{ source('raw', 'transactions') }}
),

renamed as (
    select
        try_cast(접수연도 as integer)                 as report_year,
        자치구코드                                     as sgg_code,        -- 5-digit legal district code
        자치구명                                       as district_name,
        법정동코드                                     as dong_code,       -- 5-digit legal dong code
        법정동명                                       as dong_name,
        자치구코드 || 법정동코드                        as bjd_code,        -- 10-digit, matches building register
        지번구분                                       as lot_type_code,
        지번구분명                                     as lot_type_name,
        본번                                           as main_lot_no,     -- kept as text: '0046', not 46
        부번                                           as sub_lot_no,
        건물명                                         as building_name,
        try_strptime(계약일, '%Y%m%d')::date           as contract_date,
        try_cast("물건금액(만원)" as bigint)            as price_10k_krw,
        try_cast("건물면적(㎡)" as double)              as floor_area_m2,
        try_cast("토지면적(㎡)" as double)              as land_area_m2,
        try_cast(층 as integer)                        as floor,           -- negative = basement
        권리구분                                       as right_type,      -- 분양권 / 입주권 / null
        try_strptime(취소일, '%Y%m%d')::date           as cancelled_date,
        try_cast(건축년도 as integer)                   as built_year,
        건물용도                                       as building_use,
        신고구분                                       as report_type,     -- 중개거래 / 직거래
        _source_file
    from source
)

select
    *,
    cancelled_date is not null  as is_cancelled,
    right_type is not null      as is_presale_right,
    report_type = '직거래'       as is_direct_deal
from renamed