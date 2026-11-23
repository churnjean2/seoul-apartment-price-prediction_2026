-- One row per building register record (recap title section).
-- Renames columns to English and casts types. No rows are removed here.
-- Korean source columns go through q() so the same SQL runs on
-- DuckDB (dev) and BigQuery (prod); see macros/cross_db.sql.

with source as (
    select * from {{ source('raw', 'building_register') }}
)

select
    {{ q('건축물대장일련번호') }}                                as register_id,
    {{ q('법정동코드') }}                                        as bjd_code,          -- 10-digit legal dong code
    {{ q('자치구코드') }}                                        as sgg_admin_code,    -- 7-digit ADMINISTRATIVE code: a different
                                                                                      -- system from transactions.sgg_code
    {{ q('대지구분코드명') }}                                    as lot_type_name,
    {{ q('주지번') }}                                            as main_lot_no,
    {{ q('부지번') }}                                            as sub_lot_no,
    {{ q('대지위치') }}                                          as site_address,
    trim(replace({{ q('시군구코드명') }}, '서울특별시', ''))     as district_name,     -- '서울특별시 강동구' -> '강동구'
    {{ q('법정동코드명') }}                                      as dong_name,
    {{ q('주용도코드명') }}                                      as main_use,
    {{ try_cast_to(q('세대수'), 'integer') }}                    as households,
    {{ try_cast_to(q('총주차수'), 'integer') }}                  as parking_spaces,
    {{ try_cast_to(q('승용승강기수'), 'integer') }}              as passenger_elevators,
    {{ try_cast_to(q('대지면적'), 'double') }}                   as site_area_m2,
    {{ try_cast_to(q('연면적'), 'double') }}                     as gross_floor_area_m2,
    {{ try_cast_to(q('용적률'), 'double') }}                     as floor_area_ratio,
    {{ try_cast_to(q('건폐율'), 'double') }}                     as building_coverage_ratio,
    {{ try_parse_date(q('사용승인일자'), ['%Y%m%d', '%Y-%m-%d']) }} as approval_date,
    {{ q('에너지효율등급값') }}                                  as energy_grade,
    {{ try_cast_to(q('에너지절감률'), 'double') }}               as energy_saving_rate,
    {{ try_cast_to(q('EPI점수'), 'double') }}                    as epi_score,
    {{ q('친환경건축물등급값') }}                                as green_building_grade,
    {{ try_cast_to(q('친환경건축물인증점수'), 'double') }}       as green_building_score,
    {{ try_cast_to(q('X좌표'), 'double') }}                      as x_coord,
    {{ try_cast_to(q('Y좌표'), 'double') }}                      as y_coord,
    _source_file
from source