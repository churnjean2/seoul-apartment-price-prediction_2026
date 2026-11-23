import os
import re
from pathlib import Path

import pandas as pd

DATA_DIR = Path(os.environ.get("RAW_DATA_DIR", "data/raw"))
SOURCES = {
    "transactions": "apt_price_*.csv",
    "building_register": "building_register.csv",
}

# Characters every warehouse we target accepts in a column name
_DISALLOWED = re.compile(r"[^\w\- &%=+:'<>#|]")


def clean_name(name: str) -> str:
    # Only rename what BigQuery would reject, keep everything else as is
    name = name.replace("㎡", "m2")
    name = _DISALLOWED.sub("_", name)
    return re.sub(r"_+", "_", name).rstrip("_")


def read_csv_any_encoding(path: Path) -> pd.DataFrame:
    # All columns as text so codes keep their leading zeros
    for enc in ("utf-8-sig", "cp949"):
        try:
            return pd.read_csv(path, dtype=str, encoding=enc)
        except UnicodeDecodeError:
            continue
    raise ValueError(f"Cannot decode {path}")


def build_frame(pattern: str) -> tuple[pd.DataFrame, int]:
    files = sorted(DATA_DIR.glob(pattern))
    if not files:
        raise FileNotFoundError(f"No files match {DATA_DIR / pattern}")
    frames = []
    for path in files:
        df = read_csv_any_encoding(path)
        df["_source_file"] = path.name  # lineage: which file each row came from
        frames.append(df)
    df = pd.concat(frames, ignore_index=True)
    df["_loaded_at"] = pd.Timestamp.now(tz="UTC")

    df.columns = [clean_name(c) for c in df.columns]
    if df.columns.duplicated().any():
        raise ValueError("Column names collide after cleaning")
    return df, len(files)