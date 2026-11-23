import os
from pathlib import Path

import duckdb

from raw_io import SOURCES, build_frame

DB_PATH = Path(os.environ.get("DUCKDB_PATH", "data/warehouse.duckdb"))


def main():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB_PATH))
    con.execute("create schema if not exists raw")
    for table, pattern in SOURCES.items():
        df, n_files = build_frame(pattern)
        # Idempotent: rerunning replaces the table instead of appending
        con.register("df_view", df)
        con.execute(f"create or replace table raw.{table} as select * from df_view")
        con.unregister("df_view")
        print(f"raw.{table}: {len(df):,} rows from {n_files} file(s)")
    con.close()


if __name__ == "__main__":
    main()