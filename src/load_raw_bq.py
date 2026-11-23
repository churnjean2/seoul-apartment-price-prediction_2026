import os
from pathlib import Path

from google.cloud import bigquery, storage

from raw_io import SOURCES, build_frame

PROJECT = os.environ["GCP_PROJECT"]
BUCKET = os.environ.get("GCS_BUCKET", "seoul-apt-raw")
DATASET = "raw"
STAGE_DIR = Path("data/parquet")


def main():
    STAGE_DIR.mkdir(parents=True, exist_ok=True)
    bucket = storage.Client(project=PROJECT).bucket(BUCKET)
    bq = bigquery.Client(project=PROJECT)

    for table, pattern in SOURCES.items():
        df, n_files = build_frame(pattern)

        # Parquet avoids CSV encoding issues and keeps every column as text
        local = STAGE_DIR / f"{table}.parquet"
        df.to_parquet(local, index=False)

        blob = f"raw/{table}.parquet"
        bucket.blob(blob).upload_from_filename(str(local))
        uri = f"gs://{BUCKET}/{blob}"

        # WRITE_TRUNCATE = same idempotent behaviour as CREATE OR REPLACE
        job = bq.load_table_from_uri(
            uri,
            f"{PROJECT}.{DATASET}.{table}",
            job_config=bigquery.LoadJobConfig(
                source_format=bigquery.SourceFormat.PARQUET,
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            ),
        )
        job.result()  # wait for the load to finish
        n = bq.get_table(f"{PROJECT}.{DATASET}.{table}").num_rows
        print(f"{uri} -> {DATASET}.{table}: {n:,} rows "
              f"(local {len(df):,}, {n_files} file(s))")


if __name__ == "__main__":
    main()