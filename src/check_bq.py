import os
import re
from pathlib import Path

import pandas as pd
from google.cloud import bigquery

DATA_DIR = Path(os.environ.get("RAW_DATA_DIR", "data/raw"))
PROJECT = os.environ["GCP_PROJECT"]

# Characters BigQuery accepts in column names (approximation of the
# "flexible column names" rule): letters, numbers, underscore, dash,
# space and & % = + : ' < > # |
ALLOWED = re.compile(r"^[\w\- &%=+:'<>#|]+$")


def read_header(path: Path) -> list[str]:
    # Same encoding fallback as load_raw.py, but read the header only
    for enc in ("utf-8-sig", "cp949"):
        try:
            return list(pd.read_csv(path, nrows=0, encoding=enc).columns)
        except UnicodeDecodeError:
            continue
    raise ValueError(f"Cannot decode {path}")


def main():
    # 1) Can we reach BigQuery with the service account?
    client = bigquery.Client(project=PROJECT)
    datasets = [d.dataset_id for d in client.list_datasets()]
    print(f"connected to {PROJECT}, datasets: {datasets}")

    # 2) Which raw column names would BigQuery reject?
    for path in sorted(DATA_DIR.glob("*.csv")):
        bad = [c for c in read_header(path) if not ALLOWED.match(c)]
        print(f"\n{path.name}: {len(bad)} problem column(s)")
        for c in bad:
            print(f"  {c}")


if __name__ == "__main__":
    main()