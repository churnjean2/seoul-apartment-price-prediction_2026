-- Building register with missing dong codes filled from the name lookup.
-- bjd_code_source records where each code came from, so the fill can be audited.

with buildings as (
    select * from {{ ref('stg_building_register') }}
),

lookup as (
    select * from {{ ref('int_dong_code_lookup') }}
)

select
    b.* exclude (bjd_code),
    coalesce(b.bjd_code, l.bjd_code) as bjd_code,
    case
        when b.bjd_code is not null then 'register'
        when l.bjd_code is not null then 'name_lookup'
        else 'missing'
    end as bjd_code_source
from buildings as b
left join lookup as l
    on  b.bjd_code is null
    and b.district_name = l.district_name
    and b.dong_name     = l.dong_name