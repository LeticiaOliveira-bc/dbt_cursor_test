#!/usr/bin/env python3
"""Load .env and run a command so MOTHERDUCK_TOKEN is set for dbt and other tools."""

import os
import subprocess
import sys

from dotenv import load_dotenv

load_dotenv()
# Strip token so copy-paste from .env doesn't include trailing newline/space
token = (os.environ.get("MOTHERDUCK_TOKEN") or "").strip()
if token:
    os.environ["MOTHERDUCK_TOKEN"] = token

if not sys.argv[1:]:
    sys.exit("Usage: python run_with_env.py <command> [args...]  e.g.  python run_with_env.py dbt build --profiles-dir . --project-dir . --target motherduck")

sys.exit(subprocess.run(sys.argv[1:]).returncode)
