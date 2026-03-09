with imdb as (
    select
        series_title as title,
        released_year,
        director,
        genre as imdb_genre,
        imdb_rating,
        meta_score,
        gross_revenue,
        no_of_votes
    from {{ ref('stg_imdb_movies') }}
),

netflix as (
    select
        title,
        released_year,
        director,
        content_type,
        rating as netflix_rating,
        listed_in as netflix_categories,
        date_added as netflix_added_date
    from {{ ref('stg_netflix') }}
    where content_type = 'Movie'
),

wiki as (
    select
        title,
        released_year,
        director,
        genre as wiki_genre,
        origin,
        plot
    from {{ ref('stg_wiki_movies') }}
)

select
    imdb.title,
    imdb.released_year,
    imdb.director,
    imdb.imdb_genre,
    imdb.imdb_rating,
    imdb.meta_score,
    imdb.gross_revenue,
    imdb.no_of_votes,
    netflix.netflix_rating,
    netflix.netflix_categories,
    netflix.netflix_added_date,
    wiki.wiki_genre,
    wiki.origin,
    case when netflix.title is not null then true else false end as on_netflix,
    case when wiki.title is not null then true else false end as has_wiki_plot,
    length(wiki.plot) as plot_length
from imdb
left join netflix
    on lower(trim(imdb.title)) = lower(trim(netflix.title))
    and imdb.released_year = netflix.released_year
left join wiki
    on lower(trim(imdb.title)) = lower(trim(wiki.title))
    and imdb.released_year = wiki.released_year
