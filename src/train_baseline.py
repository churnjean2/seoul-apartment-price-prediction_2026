import os
from pathlib import Path

import duckdb
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from xgboost import XGBRegressor
from sklearn.compose import TransformedTargetRegressor
import json
from datetime import datetime, timezone

import joblib

DB_PATH = Path(os.environ.get("DUCKDB_PATH", "data/warehouse.duckdb"))
SPLIT_DATE = "2026-01-01"  # train: before this date, test: on/after
SEED = 42
MODEL_DIR = Path("artifacts")

NUMERIC = [
    "floor_area_m2", "floor", "building_age", "households",
    "parking_per_household", "passenger_elevators",
    "floor_area_ratio", "building_coverage_ratio", "x_coord", "y_coord",
]
CATEGORICAL = ["district_name", "energy_grade", "green_building_grade"]
TARGET = "price_per_m2_10k"


def load_mart() -> pd.DataFrame:
    con = duckdb.connect(str(DB_PATH), read_only=True)
    df = con.execute("select * from main.mart_training_trades").df()
    con.close()
    return df


def report(name, y_true, y_pred):
    # Metrics in original units (10k KRW per m2), so they are explainable
    mae = mean_absolute_error(y_true, y_pred)
    mape = np.mean(np.abs(y_true - y_pred) / y_true) * 100
    r2 = r2_score(y_true, y_pred)
    print(f"{name:<28} R2={r2:6.3f}  MAE={mae:7.1f}  MAPE={mape:5.1f}%")
    return {"r2": round(r2, 3), "mae": round(mae, 1), "mape": round(mape, 1)}


def main():
    df = load_mart()
    df["contract_date"] = pd.to_datetime(df["contract_date"])

    # Time-based split: learn from the past, predict the future
    train = df[df["contract_date"] < SPLIT_DATE]
    test = df[df["contract_date"] >= SPLIT_DATE]
    print(f"train={len(train):,}  test={len(test):,}")

    X_train, y_train = train[NUMERIC + CATEGORICAL], train[TARGET]
    X_test, y_test = test[NUMERIC + CATEGORICAL], test[TARGET]

    # Naive baselines: a model must beat these to be worth anything
    report("baseline: global median", y_test,
           np.full(len(y_test), y_train.median()))
    district_median = train.groupby("district_name")[TARGET].median()
    report("baseline: district median", y_test,
           test["district_name"].map(district_median).fillna(y_train.median()))

    # Everything fitted on data lives inside the Pipeline, so it is
    # fitted on the training rows only (no leakage from the test set).
    preprocess = ColumnTransformer([
        ("num", SimpleImputer(strategy="median"), NUMERIC),
        # Missing certification grade = "not certified", a real category
        ("cat", Pipeline([
            ("fill", SimpleImputer(strategy="constant", fill_value="none")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]), CATEGORICAL),
    ])
    model = Pipeline([
        ("prep", preprocess),
        ("xgb", XGBRegressor(
            n_estimators=400, learning_rate=0.05, max_depth=6,
            subsample=0.8, colsample_bytree=0.8,
            random_state=SEED, n_jobs=-1,
        )),
    ])
    model.fit(X_train, y_train)
    test_metrics = report("XGBoost (time split)", y_test, model.predict(X_test))

    # Final model: refit on ALL rows so it knows the latest prices.
    # The reported score is still the time-split score above.
    features = NUMERIC + CATEGORICAL
    final = build_model()
    final.fit(df[features], df[TARGET])

    MODEL_DIR.mkdir(exist_ok=True)
    joblib.dump(final, MODEL_DIR / "model.joblib")

    # Metadata travels with the model: what it expects and how good it is
    meta = {
        "trained_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "rows": len(df),
        "data_until": df["contract_date"].max().date().isoformat(),
        "target": TARGET,
        "numeric": NUMERIC,
        "categorical": CATEGORICAL,
        "test_split_date": SPLIT_DATE,
        "test_metrics": test_metrics,
    }
    (MODEL_DIR / "model_meta.json").write_text(json.dumps(meta, indent=2))

    # Sanity check: reload the saved file and predict one row
    reloaded = joblib.load(MODEL_DIR / "model.joblib")
    sample = X_test.iloc[[0]]
    print(f"saved -> {MODEL_DIR / 'model.joblib'}")
    print(f"check: predicted={reloaded.predict(sample)[0]:.1f}  "
          f"actual={y_test.iloc[0]:.1f}")

def build_model(numeric=NUMERIC, categorical=CATEGORICAL, log_target=False):
    # Imputation and encoding are fitted inside the pipeline (train only)
    preprocess = ColumnTransformer([
        ("num", SimpleImputer(strategy="median"), numeric),
        ("cat", Pipeline([
            ("fill", SimpleImputer(strategy="constant", fill_value="none")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]), categorical),
    ])
    pipe = Pipeline([
        ("prep", preprocess),
        ("xgb", XGBRegressor(
            n_estimators=400, learning_rate=0.05, max_depth=6,
            subsample=0.8, colsample_bytree=0.8,
            random_state=SEED, n_jobs=-1,
        )),
    ])
    if log_target:
        # Train on log(price), convert predictions back to the original unit
        return TransformedTargetRegressor(
            regressor=pipe, func=np.log1p, inverse_func=np.expm1,
        )
    return pipe

if __name__ == "__main__":
    main()