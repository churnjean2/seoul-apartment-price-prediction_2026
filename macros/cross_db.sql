{# Quote a column name the way the current engine expects:
   "name" on DuckDB, `name` on BigQuery #}
{% macro q(name) -%}
    {{ adapter.quote(name) }}
{%- endmacro %}


{# Cast that returns NULL instead of failing on bad values.
   DuckDB: try_cast(x as bigint), BigQuery: safe_cast(x as int64) #}
{% macro try_cast_to(expr, type) -%}
    {%- if target.type == 'bigquery' -%}
        {%- set bq_types = {'bigint': 'int64', 'integer': 'int64',
                            'double': 'float64', 'varchar': 'string'} -%}
        safe_cast({{ expr }} as {{ bq_types.get(type, type) }})
    {%- else -%}
        try_cast({{ expr }} as {{ type }})
    {%- endif -%}
{%- endmacro %}


{# Parse text to a date, trying each format in order; NULL if none match.
   DuckDB: try_strptime(x, fmt)::date, BigQuery: safe.parse_date(fmt, x) #}
{% macro try_parse_date(expr, formats) -%}
    coalesce(
    {%- for fmt in formats %}
        {%- if target.type == 'bigquery' %}
        safe.parse_date('{{ fmt }}', {{ expr }})
        {%- else %}
        try_strptime({{ expr }}, '{{ fmt }}')::date
        {%- endif -%}
        {{ "," if not loop.last }}
    {%- endfor %}
    )
{%- endmacro %}

{# "All columns except these": DuckDB uses EXCLUDE, BigQuery uses EXCEPT #}
{% macro star_except(cols) -%}
    {%- if target.type == 'bigquery' -%}
        * except ({{ cols | join(', ') }})
    {%- else -%}
        * exclude ({{ cols | join(', ') }})
    {%- endif -%}
{%- endmacro %}

{# Date -> 'YYYY-MM' text. DuckDB: strftime(d, fmt), BigQuery: format_date(fmt, d) #}
{% macro year_month(expr) -%}
    {%- if target.type == 'bigquery' -%}
        format_date('%Y-%m', {{ expr }})
    {%- else -%}
        strftime({{ expr }}, '%Y-%m')
    {%- endif -%}
{%- endmacro %}