with netflix_movies as (
    select
        title,
        released_year,
        director,
        rating as netflix_rating,
        duration_minutes,
        listed_in,
        date_added as netflix_added_date,
        country
    from {{ ref('stg_netflix') }}
    where content_type = 'Movie'
),

imdb as (
    select
        series_title as title,
        released_year,
        imdb_rating,
        meta_score,
        no_of_votes,
        gross_revenue,
        genre as imdb_genre
    from {{ ref('stg_imdb_movies') }}
)

select
    n.title,
    n.released_year,
    n.director,
    n.netflix_rating,
    n.duration_minutes,
    n.listed_in as netflix_categories,
    n.country,
    n.netflix_added_date,
    i.imdb_rating,
    i.meta_score,
    i.no_of_votes,
    i.gross_revenue,
    i.imdb_genre,
    case
        when i.imdb_rating >= 8.0 then 'Excellent'
        when i.imdb_rating >= 7.0 then 'Good'
        when i.imdb_rating >= 6.0 then 'Average'
        when i.imdb_rating is not null then 'Below Average'
        else 'Not Rated on IMDB'
    end as imdb_tier
from netflix_movies n
left join imdb i
    on lower(trim(n.title)) = lower(trim(i.title))
    and n.released_year = i.released_year
