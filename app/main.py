import json
import os
from pathlib import Path
from typing import Optional

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel, Field

MODEL_DIR = Path(os.environ.get("MODEL_DIR", "artifacts"))

# Load once at startup, not on every request
model = joblib.load(MODEL_DIR / "model.joblib")
meta = json.loads((MODEL_DIR / "model_meta.json").read_text(encoding="utf-8"))
NUMERIC, CATEGORICAL = meta["numeric"], meta["categorical"]

app = FastAPI(
    title="Seoul Apartment Price API",
    description="Predicts price per m2 (10k KRW) for Seoul apartment trades.",
    version="0.1.0",
)


class Apartment(BaseModel):
    # Required: what a buyer always knows about a listing
    district_name: str = Field(..., description="Seoul district, e.g. 강남구")
    floor_area_m2: float = Field(..., gt=0, le=400)
    floor: int = Field(..., ge=-5, le=100)
    building_age: int = Field(..., ge=0, le=80)

    # Optional: building details, imputed the same way as in training
    x_coord: Optional[float] = None
    y_coord: Optional[float] = None
    households: Optional[float] = Field(None, ge=0)
    parking_per_household: Optional[float] = Field(None, ge=0)
    passenger_elevators: Optional[float] = Field(None, ge=0)
    floor_area_ratio: Optional[float] = Field(None, ge=0)
    building_coverage_ratio: Optional[float] = Field(None, ge=0)
    energy_grade: Optional[str] = None
    green_building_grade: Optional[str] = None


# Fail fast if the request schema and the trained model disagree
_missing = set(NUMERIC + CATEGORICAL) - set(Apartment.model_fields)
if _missing:
    raise RuntimeError(f"Request schema is missing model features: {_missing}")


def to_frame(apt: Apartment) -> pd.DataFrame:
    row = pd.DataFrame([apt.model_dump()])
    row[NUMERIC] = row[NUMERIC].astype(float)  # None -> NaN for the imputer
    cat = row[CATEGORICAL].astype(object)
    row[CATEGORICAL] = cat.where(cat.notna(), np.nan)
    return row[NUMERIC + CATEGORICAL]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/model-info")
def model_info():
    return meta


@app.post("/predict")
def predict(apt: Apartment):
    price_m2 = float(model.predict(to_frame(apt))[0])
    return {
        "price_per_m2_10k_krw": round(price_m2, 1),
        "estimated_total_10k_krw": round(price_m2 * apt.floor_area_m2),
        "model_trained_at": meta["trained_at"],
        "test_mae_10k_krw_per_m2": meta["test_metrics"]["mae"],
    }