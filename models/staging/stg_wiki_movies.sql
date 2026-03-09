with source as (
    select * from {{ source('raw', 'raw_wiki_movies') }}
),

cleaned as (
    select
        title,
        release_year as released_year,
        origin_ethnicity as origin,
        case when director = 'Unknown' then null else director end as director,
        "cast" as cast_members,
        genre,
        wiki_page,
        plot
    from source
),

filtered as (
    select *
    from cleaned
    where director is not null
      and upper(left(director, 1)) = 'H'
)

select * from filtered
