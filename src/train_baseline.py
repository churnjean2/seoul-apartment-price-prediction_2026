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

DB_PATH = Path(os.environ.get("DUCKDB_PATH", "data/warehouse.duckdb"))
SPLIT_DATE = "2026-01-01"  # train: before this date, test: on/after
SEED = 42

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
    report("XGBoost (time split)", y_test, model.predict(X_test))

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