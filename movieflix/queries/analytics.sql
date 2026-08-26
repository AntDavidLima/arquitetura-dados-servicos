-- 1. Os 5 filmes mais populares (maior numero de avaliacoes).
SELECT m.title, COUNT(r.rating_id) AS rating_count,
       ROUND(AVG(r.rating), 2) AS average_rating
FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY rating_count DESC, average_rating DESC, m.title
LIMIT 5;

-- 2. Genero com a melhor avaliacao media.
SELECT m.genre, ROUND(AVG(r.rating), 2) AS average_rating,
       COUNT(r.rating_id) AS rating_count
FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY m.genre
ORDER BY average_rating DESC, rating_count DESC
LIMIT 1;

-- 3. Pais que mais avalia filmes.
SELECT u.country, COUNT(r.rating_id) AS rating_count,
       COUNT(DISTINCT u.user_id) AS active_users
FROM users u
JOIN ratings r ON r.user_id = u.user_id
GROUP BY u.country
ORDER BY rating_count DESC, active_users DESC
LIMIT 1;

-- Data Marts.
SELECT * FROM mart_top_10_movies_by_genre ORDER BY genre, genre_rank;
SELECT * FROM mart_average_rating_by_age_group;
SELECT * FROM mart_ratings_by_country ORDER BY rating_count DESC;
