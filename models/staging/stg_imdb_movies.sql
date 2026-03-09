with source as (
    select * from {{ source('raw', 'raw_imdb') }}
),

cleaned as (
    select
        series_title,
        try_cast(released_year as integer) as released_year,
        certificate,
        try_cast(replace(runtime, ' min', '') as integer) as runtime_minutes,
        genre,
        imdb_rating,
        overview,
        try_cast(meta_score as integer) as meta_score,
        director,
        star1,
        star2,
        star3,
        star4,
        no_of_votes,
        try_cast(replace(gross, ',', '') as bigint) as gross_revenue,
        poster_link
    from source
)

select * from cleaned
