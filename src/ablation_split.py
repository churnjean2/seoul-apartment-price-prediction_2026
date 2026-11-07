import pandas as pd
from sklearn.model_selection import GroupShuffleSplit, train_test_split

from train_baseline import (
    CATEGORICAL, NUMERIC, SEED, SPLIT_DATE, TARGET, build_model, load_mart, report,
)

FEATURES = NUMERIC + CATEGORICAL


def run(name, train, test):
    model = build_model()
    model.fit(train[FEATURES], train[TARGET])
    report(name, test[TARGET], model.predict(test[FEATURES]))


def main():
    df = load_mart()
    df["contract_date"] = pd.to_datetime(df["contract_date"])

    # A) Thesis-style: random row split. The same complex appears on
    #    both sides, so the model can memorise it.
    tr, te = train_test_split(df, test_size=0.2, random_state=SEED)
    run("A random split", tr, te)

    # B) Group split: a whole complex (register_id) stays on one side.
    gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=SEED)
    tr_idx, te_idx = next(gss.split(df, groups=df["register_id"]))
    run("B group split (by complex)", df.iloc[tr_idx], df.iloc[te_idx])

    # D) Honest: train on the past, test on the future.
    run("D time split",
        df[df["contract_date"] < SPLIT_DATE],
        df[df["contract_date"] >= SPLIT_DATE])


if __name__ == "__main__":
    main()