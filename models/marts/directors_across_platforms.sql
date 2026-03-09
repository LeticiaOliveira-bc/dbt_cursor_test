with imdb_directors as (
    select
        director,
        count(*) as imdb_top_movies,
        round(avg(imdb_rating), 2) as avg_imdb_rating,
        sum(gross_revenue) as total_gross
    from {{ ref('stg_imdb_movies') }}
    where director is not null
    group by director
),

netflix_directors as (
    select
        director,
        count(*) as netflix_titles,
        count(case when content_type = 'Movie' then 1 end) as netflix_movies,
        count(case when content_type = 'TV Show' then 1 end) as netflix_shows
    from {{ ref('stg_netflix') }}
    where director is not null
    group by director
),

wiki_directors as (
    select
        director,
        count(*) as wiki_movies,
        min(released_year) as career_start,
        max(released_year) as career_end
    from {{ ref('stg_wiki_movies') }}
    where director is not null
    group by director
)

select
    coalesce(i.director, n.director, w.director) as director,
    coalesce(i.imdb_top_movies, 0) as imdb_top_movies,
    i.avg_imdb_rating,
    i.total_gross,
    coalesce(n.netflix_titles, 0) as netflix_titles,
    coalesce(n.netflix_movies, 0) as netflix_movies,
    coalesce(n.netflix_shows, 0) as netflix_shows,
    coalesce(w.wiki_movies, 0) as wiki_movies,
    w.career_start,
    w.career_end,
    (w.career_end - w.career_start) as career_span_years,
    case
        when i.director is not null and n.director is not null then 'IMDB + Netflix'
        when i.director is not null then 'IMDB only'
        when n.director is not null then 'Netflix only'
        else 'Wikipedia only'
    end as platform_presence
from imdb_directors i
full outer join netflix_directors n on lower(trim(i.director)) = lower(trim(n.director))
full outer join wiki_directors w on lower(trim(coalesce(i.director, n.director))) = lower(trim(w.director))
