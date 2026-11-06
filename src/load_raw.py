"""Load manually downloaded raw CSV files into DuckDB.

Every column is loaded as text so that codes such as parcel numbers keep
their leading zeros. Type casting happens later, in dbt staging models.

Usage (from the repository root):
    python src/load_raw.py
"""
import os
from datetime import datetime, timezone
from pathlib import Path

import duckdb
import pandas as pd

# Paths can be overridden with environment variables (e.g. inside Docker);
# the defaults are relative to the repository root.
DATA_DIR = Path(os.environ.get("RAW_DATA_DIR", "data/raw"))
DB_PATH = Path(os.environ.get("DUCKDB_PATH", "data/warehouse.duckdb"))

# Table name in the `raw` schema -> file name pattern in DATA_DIR
SOURCES = {
    "transactions": "apt_price_*.csv",  # one file per reporting year
    "building_register": "building_register.csv",
}


def read_csv_any_encoding(path: Path) -> pd.DataFrame:
    """Korean public data is often CP949 rather than UTF-8, so try both."""
    for encoding in ("utf-8-sig", "cp949"):
        try:
            return pd.read_csv(path, dtype=str, encoding=encoding)
        except UnicodeDecodeError:
            continue
    raise ValueError(f"Could not decode {path} as UTF-8 or CP949")


def load_source(con: duckdb.DuckDBPyConnection, table: str, pattern: str) -> None:
    files = sorted(DATA_DIR.glob(pattern))
    if not files:
        print(f"Skipping raw.{table}: no files match {DATA_DIR / pattern}")
        return

    frames = []
    for f in files:
        df = read_csv_any_encoding(f)
        df["_source_file"] = f.name  # lineage: which file each row came from
        frames.append(df)

    data = pd.concat(frames, ignore_index=True)
    data["_loaded_at"] = datetime.now(timezone.utc).isoformat()

    # Full refresh: the table is rebuilt on every run,
    # so running the script twice gives the same result.
    con.register("incoming", data)
    con.execute(f"CREATE OR REPLACE TABLE raw.{table} AS SELECT * FROM incoming")
    con.unregister("incoming")
    print(f"raw.{table}: {len(data):,} rows from {len(files)} file(s)")


def main() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB_PATH))
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")
    for table, pattern in SOURCES.items():
        load_source(con, table, pattern)
    con.close()


if __name__ == "__main__":
    main()