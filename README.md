# Movie Analytics — dlt + dbt + Structured Context Layer

An end-to-end analytics project demonstrating dbt's **Structured Context Layer** for conversational analytics via the dbt MCP server in Cursor.

**Datasets**:
- [IMDB Top 1000 Movies](https://www.kaggle.com/datasets/debanganghosh/imdb-dataset) — 1,000 top-rated movies with ratings, revenue, and cast
- [Wikipedia Movie Plots](https://www.kaggle.com/datasets/jrobischon/wikipedia-movie-plots) — 34,886 movies (1901–2017) with plot summaries
- [Netflix Shows](https://www.kaggle.com/datasets/shivamb/netflix-shows) — 8,807 movies and TV shows available on Netflix

## Architecture

```
Kaggle (kagglehub) → dlt pipelines → DuckDB / MotherDuck → dbt models → dbt MCP → Cursor
```

- **Ingestion**: Three dlt pipelines download datasets from Kaggle and load them as `raw.raw_imdb`, `raw.raw_wiki_movies`, and `raw.raw_netflix` into DuckDB (local file or MotherDuck cloud).
- **Transformation**: dbt builds staging and mart views with tests, descriptions, and lineage.
- **Structured Context**: The dbt MCP server exposes models, lineage, docs, and CLI to Cursor so you can query the datasets conversationally.

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

### 2. Run the ingestion pipelines

**Local DuckDB (default):**

```bash
python pipelines/load_imdb.py
python pipelines/load_wiki_movies.py
python pipelines/load_netflix.py
```

**MotherDuck (cloud):**

```bash
export MOTHERDUCK_TOKEN="your_token_here"
python pipelines/load_imdb.py --target motherduck
python pipelines/load_wiki_movies.py --target motherduck
python pipelines/load_netflix.py --target motherduck
```

### 3. Build dbt models and run tests

**Local:**

```bash
dbt build --profiles-dir . --project-dir . --target local
```

**MotherDuck:**

```bash
source .env && dbt build --profiles-dir . --project-dir . --target motherduck
```

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

Together they give Cursor both **context** (what models exist, how they relate, what columns mean) and **data access** (run actual SQL and return results).

Reload Cursor after opening the project so it picks up the MCP config.

## Models

### Staging

| Model | Description | Filters Applied |
|-------|-------------|-----------------|
| `stg_imdb_movies` | Cleaned IMDB data with parsed runtime/revenue | None |
| `stg_wiki_movies` | Cleaned Wikipedia movie plots | **Only directors starting with "H"** |
| `stg_netflix` | Cleaned Netflix titles with parsed duration | **Only directors starting with "H"** AND **only titles added in February** |

> **Context Layer Test**: The staging filters are intentionally restrictive to test whether AI assistants correctly report these constraints when answering questions. The schema descriptions explicitly document these filters so the dbt MCP can surface them.

### Marts

| Model | Description |
|-------|-------------|
| `movies_by_genre` | IMDB stats aggregated by genre |
| `movies_by_year` | IMDB stats aggregated by release year |
| `top_directors` | IMDB director rankings |
| `movies_cross_platform` | IMDB Top 1000 enriched with Netflix availability and Wikipedia plots |
| `directors_across_platforms` | Director presence and stats across IMDB, Netflix, and Wikipedia |
| `netflix_on_imdb` | Netflix movies matched against IMDB ratings with quality tiers |

### Lineage

```
raw.raw_imdb ──→ stg_imdb_movies ──→ movies_by_genre
                                  ──→ movies_by_year
                                  ──→ top_directors
                                  ──→ movies_cross_platform
                                  ──→ directors_across_platforms
                                  ──→ netflix_on_imdb

raw.raw_wiki_movies ──→ stg_wiki_movies ──→ movies_cross_platform
                                         ──→ directors_across_platforms

raw.raw_netflix ──→ stg_netflix ──→ movies_cross_platform
                                ──→ directors_across_platforms
                                ──→ netflix_on_imdb
```

## Testing the Context Layer

Ask these questions to verify the AI uses dbt metadata correctly:

**Filter awareness (should mention H-director / February constraints):**
- "How many movies are in the Wikipedia dataset?"
- "How many titles are on Netflix?"
- "List all Netflix directors"
- "Show me Netflix shows directed by Steven Spielberg"

**Cross-dataset (should note filtered joins):**
- "Which directors appear on both Netflix and IMDB?"
- "What percentage of Netflix movies are rated on IMDB?"

**Unfiltered IMDB (should answer normally):**
- "What is the average gross revenue for Drama vs Comedy movies?"
- "Which director has the most movies with high ratings?"

## Using MotherDuck

[MotherDuck](https://motherduck.com) is a cloud-hosted DuckDB service. Once data is loaded there, query it from:

- **MotherDuck Web UI** at [app.motherduck.com](https://app.motherduck.com)
- **Any DuckDB client** using `md:` as the connection string
- **Cursor** via the MCP servers

Your `.env` file must use `export` for `source .env` to work:

```
export MOTHERDUCK_TOKEN=your_token_here
```

To get your token: go to [app.motherduck.com](https://app.motherduck.com) > Settings > Access Tokens.

## Project Structure

```
├── .cursor/mcp.json                # MCP servers config (dbt + MotherDuck)
├── dbt_project.yml                 # dbt project configuration
├── profiles.yml                    # dbt connection profiles (local + motherduck)
├── requirements.txt                # Python dependencies
├── .env                            # MotherDuck token (gitignored)
├── pipelines/
│   ├── load_imdb.py                # dlt pipeline: IMDB Top 1000
│   ├── load_wiki_movies.py         # dlt pipeline: Wikipedia Movie Plots
│   └── load_netflix.py             # dlt pipeline: Netflix Shows
├── models/
│   ├── staging/
│   │   ├── schema.yml              # Sources + staging model definitions & tests
│   │   ├── stg_imdb_movies.sql     # Staging: IMDB (no filters)
│   │   ├── stg_wiki_movies.sql     # Staging: Wikipedia (H-directors only)
│   │   └── stg_netflix.sql         # Staging: Netflix (H-directors + February only)
│   └── marts/
│       ├── schema.yml              # Mart model definitions & tests
│       ├── movies_by_genre.sql     # Genre-level aggregations
│       ├── movies_by_year.sql      # Year-level aggregations
│       ├── top_directors.sql       # Director rankings
│       ├── movies_cross_platform.sql    # Cross-dataset: IMDB + Netflix + Wikipedia
│       ├── directors_across_platforms.sql # Director stats across all 3 datasets
│       └── netflix_on_imdb.sql     # Netflix movies with IMDB ratings
├── data/
│   └── imdb.duckdb                 # Local DuckDB database (gitignored)
└── target/                         # dbt artifacts (gitignored)
```

## Raw Dataset Schemas

### IMDB (`raw.raw_imdb`) — 1,000 rows

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
| star1–star4 | VARCHAR | Top 4 billed actors |
| no_of_votes | BIGINT | Number of IMDB votes |
| gross | VARCHAR | Gross revenue string |
| poster_link | VARCHAR | Poster image URL |

### Wikipedia Movie Plots (`raw.raw_wiki_movies`) — 34,886 rows

| Column | Type | Description |
|--------|------|-------------|
| release_year | BIGINT | Release year |
| title | VARCHAR | Movie title |
| origin_ethnicity | VARCHAR | Country/cultural origin |
| director | VARCHAR | Director name |
| cast | VARCHAR | Main cast members |
| genre | VARCHAR | Genre |
| wiki_page | VARCHAR | Wikipedia article URL |
| plot | VARCHAR | Full plot summary |

### Netflix Shows (`raw.raw_netflix`) — 8,807 rows

| Column | Type | Description |
|--------|------|-------------|
| show_id | VARCHAR | Netflix unique ID |
| type | VARCHAR | Movie or TV Show |
| title | VARCHAR | Title |
| director | VARCHAR | Director name(s) |
| cast | VARCHAR | Cast members |
| country | VARCHAR | Production country |
| date_added | VARCHAR | Date added to Netflix |
| release_year | BIGINT | Year of release |
| rating | VARCHAR | Content rating (PG-13, TV-MA, R, etc.) |
| duration | VARCHAR | Duration ("90 min" or "2 Seasons") |
| listed_in | VARCHAR | Netflix categories |
| description | VARCHAR | Brief description |
