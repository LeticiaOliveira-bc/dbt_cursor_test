"""Attach the shared MotherDuck database so dbt can build models against it."""

import os
import sys

import duckdb

token = os.environ.get("MOTHERDUCK_TOKEN")
if not token:
    sys.exit("ERROR: MOTHERDUCK_TOKEN environment variable is not set.")

conn = duckdb.connect(f"md:?motherduck_token={token}")
conn.execute("ATTACH 'md:_share/imdb_analytics/2cb08ffd-e0b9-4035-9356-a4a7a718bc1d'")
print("Shared database 'imdb_analytics' attached successfully.")
conn.close()
