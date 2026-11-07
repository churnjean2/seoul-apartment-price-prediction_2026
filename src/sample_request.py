import json

import pandas as pd

from train_baseline import CATEGORICAL, NUMERIC, SPLIT_DATE, TARGET, load_mart


def clean(v):
    # numpy types -> plain Python, NaN -> None (JSON null)
    if pd.isna(v):
        return None
    return v.item() if hasattr(v, "item") else v


df = load_mart()
row = df[pd.to_datetime(df["contract_date"]) >= SPLIT_DATE].iloc[0]
payload = {c: clean(row[c]) for c in NUMERIC + CATEGORICAL}
print(json.dumps(payload, ensure_ascii=False, indent=2))
print(f"actual {TARGET}: {row[TARGET]}")