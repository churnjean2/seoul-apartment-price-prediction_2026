-- One row per building register record (recap title section).
-- Renames columns to English and casts types. No rows are removed here.

with source as (
    select * from {{ source('raw', 'building_register') }}
)

select
    건축물대장일련번호                                as register_id,
    법정동코드                                       as bjd_code,          -- 10-digit legal dong code
    자치구코드                                       as sgg_admin_code,    -- 7-digit ADMINISTRATIVE code: a different
                                                                          -- system from transactions.sgg_code
    대지구분코드명                                   as lot_type_name,
    주지번                                           as main_lot_no,
    부지번                                           as sub_lot_no,
    대지위치                                         as site_address,
    trim(replace(시군구코드명, '서울특별시', ''))    as district_name,  -- '서울특별시 강동구' -> '강동구'
    법정동코드명                                     as dong_name,
    주용도코드명                                     as main_use,
    try_cast(세대수 as integer)                      as households,
    try_cast(총주차수 as integer)                    as parking_spaces,
    try_cast(승용승강기수 as integer)                as passenger_elevators,
    try_cast(대지면적 as double)                     as site_area_m2,
    try_cast(연면적 as double)                       as gross_floor_area_m2,
    try_cast(용적률 as double)                       as floor_area_ratio,
    try_cast(건폐율 as double)                       as building_coverage_ratio,
    try_strptime(사용승인일자, ['%Y%m%d', '%Y-%m-%d'])::date as approval_date,
    에너지효율등급값                                  as energy_grade,
    try_cast(에너지절감률 as double)                  as energy_saving_rate,
    try_cast(EPI점수 as double)                      as epi_score,
    친환경건축물등급값                                as green_building_grade,
    try_cast(친환경건축물인증점수 as double)          as green_building_score,
    try_cast(X좌표 as double)                        as x_coord,
    try_cast(Y좌표 as double)                        as y_coord,
    _source_file
from source