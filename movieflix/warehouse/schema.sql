CREATE TABLE IF NOT EXISTS movies (
    movie_id INTEGER PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    genre VARCHAR(80) NOT NULL,
    release_year SMALLINT NOT NULL CHECK (release_year BETWEEN 1888 AND 2100)
);

CREATE TABLE IF NOT EXISTS users (
    user_id INTEGER PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    age SMALLINT NOT NULL CHECK (age BETWEEN 1 AND 120),
    country VARCHAR(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS ratings (
    rating_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    movie_id INTEGER NOT NULL REFERENCES movies(movie_id),
    rating NUMERIC(2, 1) NOT NULL CHECK (rating BETWEEN 0 AND 5),
    rated_at DATE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ratings_movie ON ratings(movie_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user ON ratings(user_id);

CREATE OR REPLACE VIEW mart_top_10_movies_by_genre AS
WITH movie_scores AS (
    SELECT
        m.genre,
        m.movie_id,
        m.title,
        ROUND(AVG(r.rating), 2) AS average_rating,
        COUNT(r.rating_id) AS rating_count
    FROM movies m
    JOIN ratings r ON r.movie_id = m.movie_id
    GROUP BY m.genre, m.movie_id, m.title
),
ranked AS (
    SELECT
        movie_scores.*,
        ROW_NUMBER() OVER (
            PARTITION BY genre
            ORDER BY average_rating DESC, rating_count DESC, title
        ) AS genre_rank
    FROM movie_scores
)
SELECT genre, genre_rank, movie_id, title, average_rating, rating_count
FROM ranked
WHERE genre_rank <= 10;

CREATE OR REPLACE VIEW mart_average_rating_by_age_group AS
SELECT
    CASE
        WHEN u.age BETWEEN 13 AND 17 THEN '13-17'
        WHEN u.age BETWEEN 18 AND 25 THEN '18-25'
        WHEN u.age BETWEEN 26 AND 35 THEN '26-35'
        WHEN u.age BETWEEN 36 AND 50 THEN '36-50'
        ELSE '51+'
    END AS age_group,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(r.rating_id) AS rating_count
FROM users u
JOIN ratings r ON r.user_id = u.user_id
GROUP BY 1
ORDER BY MIN(u.age);

CREATE OR REPLACE VIEW mart_ratings_by_country AS
SELECT
    u.country,
    COUNT(r.rating_id) AS rating_count,
    COUNT(DISTINCT u.user_id) AS active_users,
    ROUND(AVG(r.rating), 2) AS average_rating
FROM users u
JOIN ratings r ON r.user_id = u.user_id
GROUP BY u.country;
