"""Attach the shared MotherDuck database so dbt can build models against it."""

import os
import sys

import duckdb
from dotenv import load_dotenv

load_dotenv()
token = (os.environ.get("MOTHERDUCK_TOKEN") or "").strip()
if not token:
    sys.exit("ERROR: MOTHERDUCK_TOKEN not set. Put it in .env or set the environment variable.")

conn = duckdb.connect(f"md:?motherduck_token={token}")

# Only attach if not already attached (idempotent)
attached = [row[1] for row in conn.execute("PRAGMA database_list").fetchall()]
if "imdb_analytics" not in attached:
    conn.execute("ATTACH 'md:_share/imdb_analytics/2cb08ffd-e0b9-4035-9356-a4a7a718bc1d'")
    print("Shared database 'imdb_analytics' attached successfully.")
else:
    print("Shared database 'imdb_analytics' is already attached.")
conn.close()
