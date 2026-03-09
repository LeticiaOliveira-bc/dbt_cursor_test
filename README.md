# IMDB Analytics - dlt + dbt + Structured Context Layer

An end-to-end analytics project demonstrating dbt's **Structured Context Layer** for conversational analytics via the dbt MCP server in Cursor.

**Data**: IMDB Top 1000 Movies dataset from [Kaggle](https://www.kaggle.com/datasets/debanganghosh/imdb-dataset).

## Architecture

```
Kaggle (kagglehub) → dlt pipeline → DuckDB / MotherDuck → dbt models → dbt MCP → Cursor
```

- **Ingestion**: A dlt pipeline downloads the IMDB dataset from Kaggle and loads it as `raw.raw_imdb` into DuckDB (local file or MotherDuck cloud).
- **Transformation**: dbt builds staging and mart views on top of the raw data with tests, descriptions, and lineage.
- **Structured Context**: The dbt MCP server exposes models, lineage, docs, and CLI to Cursor so you can query the dataset conversationally.

## Prerequisites

- Python 3.9+
- Kaggle API credentials at `~/.kaggle/kaggle.json` ([instructions](https://www.kaggle.com/docs/api#authentication))
- [uv](https://github.com/astral-sh/uv) installed (for `uvx` to run dbt-mcp)
- (Optional) [MotherDuck](https://motherduck.com) account + token for cloud-hosted DuckDB

## Quick Start

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Run the ingestion pipeline

**Local DuckDB (default):**

```bash
python pipelines/load_imdb.py
```

**MotherDuck (cloud):**

```bash
export MOTHERDUCK_TOKEN="your_token_here"
python pipelines/load_imdb.py --target motherduck
```

This downloads the IMDB Top 1000 dataset and loads 1000 rows into the chosen destination.

### 3. Build dbt models and run tests

**Local:**

```bash
dbt build --profiles-dir . --project-dir . --target local
```

**MotherDuck:**

```bash
export MOTHERDUCK_TOKEN="your_token_here"
dbt build --profiles-dir . --project-dir . --target motherduck
```

This creates:
- **Staging**: `stg_imdb_movies` — cleaned, typed view of the raw data
- **Marts**:
  - `movies_by_genre` — stats aggregated by genre
  - `movies_by_year` — stats aggregated by release year
  - `top_directors` — director rankings

### 4. Generate dbt docs

```bash
dbt docs generate --profiles-dir . --project-dir .
```

### 5. Use MCP servers in Cursor

The `.cursor/mcp.json` is already configured with **two MCP servers**:

| MCP Server | Purpose |
|---|---|
| **dbt** (`dbt-mcp`) | Structured context: model metadata, lineage, docs, dbt CLI commands |
| **mcp-server-motherduck** | Direct SQL execution: run queries against DuckDB/MotherDuck from Cursor |

Together they give Cursor both **context** (what models exist, how they relate, what columns mean) and **data access** (run actual SQL and return results). This is the full structured context layer in action.

Reload Cursor after opening the project so it picks up the MCP config.

You can now ask Cursor questions like:
- "What models are in this dbt project?" (uses dbt MCP)
- "Show me the lineage for `movies_by_genre`" (uses dbt MCP)
- "Run `dbt test`" (uses dbt MCP)
- "What are the top 10 highest-rated genres?" (uses DuckDB MCP to run SQL)
- "Which director has the most movies in the IMDB top 1000?" (uses DuckDB MCP)
- "Describe the raw_imdb table schema" (uses DuckDB MCP)

The dbt MCP provides structured context (model descriptions, column docs, lineage, tests) while the DuckDB/MotherDuck MCP lets the AI run actual queries and inspect results -- closing the feedback loop as described in [MCP + DuckDB: Connect AI Assistants to Your Data Pipelines](https://motherduck.com/blog/faster-data-pipelines-with-mcp-duckdb-ai/).

## Using MotherDuck

[MotherDuck](https://motherduck.com) is a cloud-hosted DuckDB service. Once the data is loaded there, you can query it from:

- **MotherDuck Web UI** at [app.motherduck.com](https://app.motherduck.com)
- **Any DuckDB client** using `md:` as the connection string
- **Cursor** via the MCP servers

Example queries in the MotherDuck UI:

```sql
SELECT * FROM main_marts.movies_by_genre ORDER BY avg_imdb_rating DESC;

SELECT * FROM main_marts.top_directors LIMIT 20;

SELECT director, series_title, imdb_rating
FROM main_staging.stg_imdb_movies
WHERE imdb_rating >= 8.5
ORDER BY imdb_rating DESC;
```

To get your token: go to [app.motherduck.com](https://app.motherduck.com) > Settings > Access Tokens.

**Important**: Your `.env` file must use `export` for `source .env` to work with subprocesses:

```
export MOTHERDUCK_TOKEN=your_token_here
```

Then run:

```bash
source .env && python pipelines/load_imdb.py --target motherduck
source .env && dbt build --profiles-dir . --project-dir . --target motherduck
```

## Project Structure

```
├── .cursor/mcp.json            # MCP servers config (dbt + DuckDB/MotherDuck)
├── dbt_project.yml             # dbt project configuration
├── profiles.yml                # dbt connection profile (DuckDB)
├── requirements.txt            # Python dependencies
├── pipelines/
│   └── load_imdb.py            # dlt ingestion pipeline
├── models/
│   ├── staging/
│   │   ├── schema.yml          # Source + staging model definitions, tests
│   │   └── stg_imdb_movies.sql # Staging model (clean/type raw data)
│   └── marts/
│       ├── schema.yml          # Mart model definitions, tests
│       ├── movies_by_genre.sql # Genre-level aggregations
│       ├── movies_by_year.sql  # Year-level aggregations
│       └── top_directors.sql   # Director rankings
├── data/
│   └── imdb.duckdb             # DuckDB database (gitignored)
└── target/                     # dbt artifacts (gitignored)
```

## Dataset Columns (raw)

| Column | Type | Description |
|--------|------|-------------|
| series_title | VARCHAR | Movie title |
| released_year | VARCHAR | Release year |
| certificate | VARCHAR | Age certification (UA, A, PG-13, R, etc.) |
| runtime | VARCHAR | Runtime string (e.g. "142 min") |
| genre | VARCHAR | Comma-separated genres |
| imdb_rating | DOUBLE | IMDB rating (1-10) |
| overview | VARCHAR | Plot summary |
| meta_score | DOUBLE | Metacritic score (0-100) |
| director | VARCHAR | Director name |
| star1-star4 | VARCHAR | Top 4 billed actors |
| no_of_votes | BIGINT | Number of IMDB votes |
| gross | VARCHAR | Gross revenue string |
| poster_link | VARCHAR | Poster image URL |
