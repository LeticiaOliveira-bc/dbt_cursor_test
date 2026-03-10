# Movie Analytics — dlt + dbt + Structured Context Layer

Testing dbt's **Structured Context Layer** for conversational analytics via MCP in Cursor.

---

## Query the data on MotherDuck (no setup, no scripts)

You can explore and query the data on MotherDuck from Cursor **without cloning this repo or running any scripts**.

### 1. Connect MotherDuck in Cursor

- Open **Cursor → Settings** (or **File → Preferences → Settings** on Windows/Linux).
- In the left sidebar, click **MCP**.
- Add the **MotherDuck** server if it’s not there, then click **Connect**.
- A browser popup will open—sign in with your MotherDuck account. When it’s done, you’re connected.

### 2. Project rule so the AI uses table and column comments

So that when you ask questions about the data, the AI reads the business rules stored in table/column comments, this repo includes a **project rule** in `.cursor/rules/`.

**Right way (project rules):** Cursor applies rules from **`.cursor/rules/`** in the project. Each rule is a `.mdc` file with YAML frontmatter. This project already has:

- **`.cursor/rules/motherduck-comments.mdc`** — tells the AI to read table/view and column comments before writing or interpreting MotherDuck queries and to surface important constraints to you.

You don’t need to do anything else: open this project in Cursor and the rule is active. If you clone the repo elsewhere, the rule travels with it.

**If you need to add or change rules:** create or edit `.mdc` files under `.cursor/rules/`. Example structure:

```markdown
---
description: Short description (shown in rule picker)
alwaysApply: true
---

Your rule content here...
```

Use `alwaysApply: true` for rules that should apply in every chat in this project, or `globs: "**/*.sql"` (and `alwaysApply: false`) to limit the rule to certain files.

---

## Setup (for running scripts and building the project)

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

---

## Use the existing MotherDuck database (quick)

```bash
python attach_shared_db.py
python run_with_env.py dbt build --profiles-dir . --project-dir . --target motherduck
```

Restart Cursor and start asking questions.

**Persisting dbt metadata in the database:** The project is configured so dbt pushes model and column descriptions from `schema.yml` into the database as `COMMENT ON TABLE` / `COMMENT ON COLUMN` (see `dbt_project.yml`: `+persist_docs: relation: true, columns: true`). That way, when you query MotherDuck via MCP (e.g. `list_tables`, `list_columns`), table and column comments reflect the business rules and semantics defined in dbt, so the AI can use them when writing or interpreting queries.

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
