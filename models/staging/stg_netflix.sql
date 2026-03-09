with source as (
    select * from {{ source('raw', 'raw_netflix') }}
),

cleaned as (
    select
        show_id,
        type as content_type,
        title,
        director,
        "cast" as cast_members,
        country,
        try_cast(strptime(trim(date_added), '%B %d, %Y') as date) as date_added,
        release_year as released_year,
        rating,
        case
            when type = 'Movie'
            then try_cast(replace(duration, ' min', '') as integer)
        end as duration_minutes,
        case
            when type = 'TV Show'
            then try_cast(replace(replace(duration, ' Seasons', ''), ' Season', '') as integer)
        end as seasons,
        listed_in,
        description
    from source
),

filtered as (
    select *
    from cleaned
    where director is not null
      and upper(left(director, 1)) = 'H'
      and date_added is not null
      and month(date_added) = 2
)

select * from filtered
