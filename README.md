# Movie Analytics — dlt + dbt + Structured Context Layer

Testing dbt's **Structured Context Layer** for conversational analytics via MCP in Cursor.

## Use the existing MotherDuck database (quick)

```bash
export MOTHERDUCK_TOKEN="your_token_here"
python attach_shared_db.py
dbt build --profiles-dir . --project-dir . --target motherduck
```

Restart Cursor and start asking questions.

---

## Run the full pipeline from scratch

Requires Kaggle API credentials at `~/.kaggle/kaggle.json`.

```bash
pip install -r requirements.txt

# Load data
export MOTHERDUCK_TOKEN="your_token_here"
python pipelines/load_imdb.py --target motherduck
python pipelines/load_wiki_movies.py --target motherduck
python pipelines/load_netflix.py --target motherduck

# Build models
dbt build --profiles-dir . --project-dir . --target motherduck
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
