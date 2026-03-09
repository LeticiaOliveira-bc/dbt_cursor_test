"""
dlt pipeline: Download Netflix Shows dataset from Kaggle and load into DuckDB.

Supports two destinations:
  --target local       -> data/imdb.duckdb (default)
  --target motherduck  -> md:imdb_analytics (requires MOTHERDUCK_TOKEN env var)

Prerequisites:
  - Kaggle API credentials at ~/.kaggle/kaggle.json
  - pip install -r requirements.txt
  - For MotherDuck: export MOTHERDUCK_TOKEN="your_token"
"""

import argparse
import os
import sys

from dotenv import load_dotenv

import dlt
import kagglehub
import pandas as pd

DATASET_HANDLE = "shivamb/netflix-shows"
LOCAL_DB_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "imdb.duckdb")


def get_destination(target: str):
    if target == "motherduck":
        load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))
        token = (os.environ.get("MOTHERDUCK_TOKEN") or "").strip()
        if not token:
            sys.exit("MOTHERDUCK_TOKEN environment variable is required for --target motherduck")
        conn_str = f"md:imdb_analytics?motherduck_token={token}"
        return dlt.destinations.motherduck(conn_str), "md:imdb_analytics"

    db_abs = os.path.abspath(LOCAL_DB_PATH)
    os.makedirs(os.path.dirname(db_abs), exist_ok=True)
    return dlt.destinations.duckdb(db_abs), db_abs


def load_netflix(target: str):
    cache_path = kagglehub.dataset_download(DATASET_HANDLE)
    csv_files = [f for f in os.listdir(cache_path) if f.endswith(".csv")]
    if not csv_files:
        sys.exit(f"No CSV files found in dataset at {cache_path}")
    csv_path = os.path.join(cache_path, csv_files[0])
    print(f"Reading {csv_path}...")

    df = pd.read_csv(csv_path)
    print(f"Loaded {len(df)} rows, {len(df.columns)} columns")
    print(f"Columns: {list(df.columns)}")
    print(df.head())

    destination, dest_label = get_destination(target)

    pipeline = dlt.pipeline(
        pipeline_name="netflix_pipeline",
        destination=destination,
        dataset_name="raw",
    )

    load_info = pipeline.run(
        df.to_dict(orient="records"),
        table_name="raw_netflix",
        write_disposition="replace",
    )
    print(load_info)
    print(f"Data loaded into {dest_label}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Load Netflix Shows dataset into DuckDB")
    parser.add_argument(
        "--target",
        choices=["local", "motherduck"],
        default="local",
        help="Destination: 'local' for file-based DuckDB, 'motherduck' for cloud (default: local)",
    )
    args = parser.parse_args()
    load_netflix(args.target)
