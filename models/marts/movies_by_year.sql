with movies as (
    select * from {{ ref('stg_imdb_movies') }}
    where released_year is not null
),

ranked as (
    select
        *,
        row_number() over (partition by released_year order by imdb_rating desc) as rn
    from movies
)

select
    released_year,
    count(*) as movie_count,
    round(avg(imdb_rating), 2) as avg_imdb_rating,
    round(avg(meta_score), 1) as avg_meta_score,
    sum(gross_revenue) as total_gross_revenue,
    max(case when rn = 1 then series_title end) as top_movie
from ranked
group by released_year
order by released_year desc
