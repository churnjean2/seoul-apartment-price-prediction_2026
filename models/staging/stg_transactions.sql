-- One row per reported trade (all building types).
-- Renames columns to English, casts types, and flags rows that
-- later models will exclude. No rows are removed here.
-- Korean source columns go through q() so the same SQL runs on
-- DuckDB (dev) and BigQuery (prod); see macros/cross_db.sql.

with source as (
    select * from {{ source('raw', 'transactions') }}
),

renamed as (
    select
        {{ try_cast_to(q('접수연도'), 'integer') }}          as report_year,
        {{ q('자치구코드') }}                                as sgg_code,        -- 5-digit legal district code
        {{ q('자치구명') }}                                  as district_name,
        {{ q('법정동코드') }}                                as dong_code,       -- 5-digit legal dong code
        {{ q('법정동명') }}                                  as dong_name,
        {{ q('자치구코드') }} || {{ q('법정동코드') }}       as bjd_code,        -- 10-digit, matches building register
        {{ q('지번구분') }}                                  as lot_type_code,
        {{ q('지번구분명') }}                                as lot_type_name,
        {{ q('본번') }}                                      as main_lot_no,     -- kept as text: '0046', not 46
        {{ q('부번') }}                                      as sub_lot_no,
        {{ q('건물명') }}                                    as building_name,
        {{ try_parse_date(q('계약일'), ['%Y%m%d']) }}        as contract_date,
        {{ try_cast_to(q('물건금액_만원'), 'bigint') }}      as price_10k_krw,
        {{ try_cast_to(q('건물면적_m2'), 'double') }}        as floor_area_m2,
        {{ try_cast_to(q('토지면적_m2'), 'double') }}        as land_area_m2,
        {{ try_cast_to(q('층'), 'integer') }}                as floor,           -- negative = basement
        {{ q('권리구분') }}                                  as right_type,      -- 분양권 / 입주권 / null
        {{ try_parse_date(q('취소일'), ['%Y%m%d']) }}        as cancelled_date,
        {{ try_cast_to(q('건축년도'), 'integer') }}          as built_year,
        {{ q('건물용도') }}                                  as building_use,
        {{ q('신고구분') }}                                  as report_type,     -- 중개거래 / 직거래
        _source_file
    from source
)

select
    *,
    cancelled_date is not null  as is_cancelled,
    right_type is not null      as is_presale_right,
    report_type = '직거래'       as is_direct_deal
from renamed