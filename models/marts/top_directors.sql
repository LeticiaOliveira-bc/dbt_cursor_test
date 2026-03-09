with movies as (
    select * from {{ ref('stg_imdb_movies') }}
),

ranked as (
    select
        *,
        row_number() over (partition by director order by imdb_rating desc) as rn
    from movies
)

select
    director,
    count(*) as movie_count,
    round(avg(imdb_rating), 2) as avg_imdb_rating,
    round(avg(meta_score), 1) as avg_meta_score,
    sum(gross_revenue) as total_gross_revenue,
    max(case when rn = 1 then series_title end) as best_movie
from ranked
group by director
order by movie_count desc, avg_imdb_rating desc
