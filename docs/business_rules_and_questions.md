# Business Rules and Questions in the Data Models

This document summarizes the **business rules** encoded in the staging and marts tables, and the **business questions** each rule supports.

---

## Staging layer – business rules

### 1. **stg_imdb_movies**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **Every movie must have a title** | `not_null` on `series_title` | "What movies are in the dataset?" |
| **Every movie must have an IMDB rating** | `not_null` on `imdb_rating` | "What is the rating of each movie?" |
| **Every movie must have a director** | `not_null` on `director` | "Who directed each movie?" |
| **Year must be a valid integer** | `try_cast(released_year as integer)` | "In which year was this released?" |
| **Runtime is in minutes (numeric)** | `try_cast(replace(runtime, ' min', '') as integer)` | "How long is the movie?" |
| **Gross revenue is numeric (no commas)** | `try_cast(replace(gross, ',', '') as bigint)` | "What was the box office?" |

---

### 2. **stg_netflix**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **Director names starting with "H" are hidden** | `case when upper(left(trim(director), 1)) = 'H' then null else director end` | Data quality / consistency with wiki (see below). |
| **Content type is only Movie or TV Show** | `accepted_values: ['Movie', 'TV Show']` | "How many movies vs shows?" |
| **Each Netflix title has a unique ID** | `unique` on `show_id` | "How many distinct titles?" |
| **Duration: minutes for movies, seasons for TV** | `duration_minutes` (movies), `seasons` (TV) | "How long is this movie/show?" |
| **Date added is a real date** | `strptime(trim(date_added), '%B %d, %Y')` | "When was it added to Netflix?" |

---

### 3. **stg_wiki_movies**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **Only directors whose name starts with "H"** | `where director is not null and upper(left(director, 1)) = 'H'` | "Which 'H' directors have Wikipedia plots?" (subset for demos/tests.) |
| **Unknown director → null** | `case when director = 'Unknown' then null else director end` | "Which movies have a known director?" |
| **No rows without a director** | Filter keeps only `director is not null` | Ensures every wiki row has a director. |

**Note:** The "H" rule in both `stg_netflix` and `stg_wiki_movies` is a **deliberate data subset**: Netflix hides "H" directors, Wiki keeps only "H" directors, so joins align on a controlled subset (e.g. Howard Hawks, Hitchcock).

---

## Marts layer – business rules and questions

### 4. **movies_cross_platform**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **IMDB is the grain; Netflix and Wiki are optional** | `from imdb left join netflix left join wiki` | "Which top IMDB movies are on Netflix?" / "Do they have a wiki plot?" |
| **Match to Netflix by title + year** | `lower(trim(title))` and `released_year` | "Is this exact movie on Netflix?" |
| **Match to Wiki by title + year** | Same logic | "Is there a Wikipedia plot for this movie?" |
| **Only Netflix movies (no TV)** | Netflix side from `content_type = 'Movie'` | "Which *movies* from the catalog are on Netflix?" |
| **Explicit flags** | `on_netflix`, `has_wiki_plot`, `plot_length` | "Which top movies are on Netflix?", "Which have long plot summaries?" |

---

### 5. **netflix_on_imdb**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **Netflix catalog is the grain** | `from netflix_movies n left join imdb i` | "What do we have on Netflix and how does it rate on IMDB?" |
| **Only movies** | `where content_type = 'Movie'` | "How do Netflix *movies* perform on IMDB?" |
| **Match by title + year** | Same as cross_platform | "Is this Netflix movie in the IMDB top 1000?" |
| **IMDB quality tiers** | `Excellent (≥8)`, `Good (≥7)`, `Average (≥6)`, `Below Average (<6)`, `Not Rated` | "How many Netflix movies are Excellent on IMDB?", "What tier is this title?" |

---

### 6. **directors_across_platforms**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **Director is the grain across 3 sources** | Full outer join IMDB, Netflix, Wiki by director name (trimmed, lower) | "Which directors appear on which platforms?" |
| **Counts by platform** | `imdb_top_movies`, `netflix_movies`, `netflix_shows`, `wiki_movies` | "How many movies per director on each platform?" |
| **Career span from Wiki** | `career_start`, `career_end`, `career_span_years` | "Who has the longest career?" |
| **Platform presence label** | `IMDB + Netflix`, `IMDB only`, `Netflix only`, `Wikipedia only` | "Who is Netflix-only?", "Who is on both IMDB and Netflix?" |

---

### 7. **top_directors**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **One row per director (IMDB only)** | `group by director` from `stg_imdb_movies` | "Who are the top directors in the IMDB 1000?" |
| **Best movie = highest-rated** | `row_number() over (partition by director order by imdb_rating desc)` then `max(case when rn = 1 ...)` | "What is each director's best movie?" |
| **Order by volume then quality** | `order by movie_count desc, avg_imdb_rating desc` | "Who has the most top movies?", "Who has the highest average rating?" |

---

### 8. **movies_by_year**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **One row per release year** | `group by released_year` | "How many top movies per year?" |
| **Only years we can use** | `where released_year is not null` | "Which years are in scope?" |
| **Top movie of the year** | Same window pattern as top_directors | "What was the best movie each year?" |
| **Order newest first** | `order by released_year desc` | "How did recent years perform?" |

---

### 9. **movies_by_genre**

| Rule | Implementation | Questions it supports |
|------|----------------|------------------------|
| **One row per genre (unnested)** | `unnest(string_split(genre, ','))` then `group by genre` | "How many movies per genre?", "Which genre has the best ratings?" |
| **A movie can count in multiple genres** | No dedup; same title in many genre rows | "What is the total count per genre (with overlap)?" |
| **Genre-level metrics** | `avg_imdb_rating`, `avg_meta_score`, `total_gross_revenue`, `avg_runtime_minutes` | "Which genre earns the most?", "Which is longest on average?" |

---

## Summary: rules → questions

| Area | Main rules | Example questions |
|------|------------|-------------------|
| **Staging** | Not null: title, rating, director (IMDB); "H" director handling (Netflix/Wiki); types and IDs | "What is in each source?", "Who is the director?" |
| **Cross-platform** | IMDB grain; match by title + year; only movies for Netflix; on_netflix / has_wiki_plot | "Which top movies are on Netflix?", "Which have wiki plots?" |
| **Netflix quality** | Netflix grain; title+year match; IMDB tiers (Excellent/Good/Average/etc.) | "How good are Netflix movies on IMDB?", "What tier is this?" |
| **Directors** | Director grain; full outer join; career span; platform presence | "Who is on which platform?", "Who has the longest career?" |
| **Rankings** | Best movie per director/year; order by count and rating | "Who are the top directors?", "Best movie per year?" |
| **Genres & years** | Unnest genres; one row per year; aggregates | "Best genre by rating?", "Movies per year?" |

---

*Generated from the dbt models and schema in this project.*
