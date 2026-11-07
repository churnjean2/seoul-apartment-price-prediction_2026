import duckdb

con = duckdb.connect("data/warehouse.duckdb", read_only=True)
print(con.execute(
    "select table_schema, table_name from information_schema.tables "
    "where table_name like 'mart%'"
).fetchall())