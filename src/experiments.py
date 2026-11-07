import pandas as pd

from train_baseline import (
    CATEGORICAL, NUMERIC, SPLIT_DATE, TARGET, build_model, load_mart, report,
)

CERT = ["energy_grade", "green_building_grade"]
WITH_DONG = CATEGORICAL + ["bjd_code"]

# One change per row, all on the same time split
EXPERIMENTS = [
    # name,                          numeric, categorical,                          log
    ("D  baseline (time split)",     NUMERIC, CATEGORICAL,                          False),
    ("E  + log target",              NUMERIC, CATEGORICAL,                          True),
    ("F  + dong code",               NUMERIC, WITH_DONG,                            True),
    ("G  F without certification",   NUMERIC, [c for c in WITH_DONG if c not in CERT], True),
]


def main():
    df = load_mart()
    df["contract_date"] = pd.to_datetime(df["contract_date"])
    train = df[df["contract_date"] < SPLIT_DATE]
    test = df[df["contract_date"] >= SPLIT_DATE]

    for name, num, cat, log in EXPERIMENTS:
        model = build_model(num, cat, log)
        model.fit(train[num + cat], train[TARGET])
        report(name, test[TARGET], model.predict(test[num + cat]))


if __name__ == "__main__":
    main()