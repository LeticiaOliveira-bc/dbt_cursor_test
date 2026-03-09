# Movie Analytics — dlt + dbt + Structured Context Layer

Testing dbt's **Structured Context Layer** for conversational analytics via MCP in Cursor.

## Setup

Create and activate a virtualenv, then install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate   # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

Add a `.env` in the project root with your MotherDuck token (one line, no spaces around `=`):

```
MOTHERDUCK_TOKEN=your_token_here
```

Scripts and `run_with_env.py` load the token from `.env` so you don't need to export it.

## Use the existing MotherDuck database (quick)

```bash
python attach_shared_db.py
python run_with_env.py dbt build --profiles-dir . --project-dir . --target motherduck
```

Restart Cursor and start asking questions.

---

## Run the full pipeline from scratch

Requires Kaggle API credentials at `~/.kaggle/kaggle.json`.

```bash
# Load data (token loaded from .env by each script)
python pipelines/load_imdb.py --target motherduck
python pipelines/load_wiki_movies.py --target motherduck
python pipelines/load_netflix.py --target motherduck

# Build models
python run_with_env.py dbt build --profiles-dir . --project-dir . --target motherduck
```

---

## Models

### Staging

| Model | Filters |
|-------|---------|
| `stg_imdb_movies` | None |
| `stg_wiki_movies` | Only directors starting with "H" |
| `stg_netflix` | Only directors starting with "H" + added in February |

### Marts

| Model | Description |
|-------|-------------|
| `movies_by_genre` | IMDB stats by genre |
| `movies_by_year` | IMDB stats by year |
| `top_directors` | IMDB director rankings |
| `movies_cross_platform` | IMDB + Netflix + Wikipedia joined |
| `directors_across_platforms` | Director stats across all 3 datasets |
| `netflix_on_imdb` | Netflix movies with IMDB ratings |

## Testing the Context Layer

Ask these to verify AI uses the dbt metadata:

- "How many movies are in the Wikipedia dataset?" (should mention H-director filter)
- "How many titles are on Netflix?" (should mention H-director + February filter)
- "Show me Netflix shows directed by Steven Spielberg" (should say he's excluded)
- "What is the average gross revenue for Drama vs Comedy?" (should answer normally)
