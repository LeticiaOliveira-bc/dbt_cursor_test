with movies as (
    select * from {{ ref('stg_imdb_movies') }}
),

genres_unnested as (
    select
        trim(unnest(string_split(genre, ','))) as genre,
        series_title,
        imdb_rating,
        meta_score,
        gross_revenue,
        runtime_minutes
    from movies
)

select
    genre,
    count(*) as movie_count,
    round(avg(imdb_rating), 2) as avg_imdb_rating,
    round(avg(meta_score), 1) as avg_meta_score,
    sum(gross_revenue) as total_gross_revenue,
    round(avg(runtime_minutes), 0) as avg_runtime_minutes
from genres_unnested
group by genre
order by movie_count desc
