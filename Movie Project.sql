-- 40 Years of Film End-to-End Data Analytics Project

/* Project Overview: 

I've developed a growing interest in film, which has led me to explore movies from different decades, 
spanning the 1950s to the present day, as well as international cinema. 

This interest sparked my curiosity about how the film industry has evolved over time, 
particularly in terms of audience preferences, box office performance and profitability. 
I was also interested in examining trends in audience ratings, the production companies 
behind films, the directors and actors shaping the industry and how box office revenue 
has changed over the years. More broadly, I wanted to explore how developments such as the 
rise of streaming platforms and social media may have influenced the industry.

Using movie data spanning four decades (1980–2019), I set out to investigate these trends across a range 
of attributes, with a particular focus on revenue, profitability and audience ratings. 
The project combines my personal interest in film with data analytics to examine how the industry has 
changed and identify interesting patterns and trends over time.

*/


/* Checking distribution of yearly data to see if there is adequate data for each year */

SELECT
    year,
    COUNT(*)
FROM dbo.movies
GROUP BY year
ORDER BY year ASC;

/* Because of the lack of data available for the year 2020 - this data will be removed in the analysis */

DELETE FROM dbo.movies 
WHERE year = 2020;


-- Analysis

-- Question 1: Which director has directed the most films during this period? How many films have they directed in total and what is their combined runtime?
SELECT TOP 1
    director,
    COUNT(*) AS movies_made,
    SUM(runtime) AS total_runtime_mins
FROM dbo.movies
WHERE director IS NOT NULL
GROUP BY director
ORDER BY movies_made DESC;


-- Question 2: Identify all movie-director combinations in which Tom Cruise is the star.
SELECT
    name,
    director
FROM dbo.movies
WHERE star = 'Tom Cruise'


-- Question 3: How many films were released in each decade and what was the average rating of these films?
SELECT
	CASE
		WHEN year >= 1980 AND year < 1990 THEN '1980s'
		WHEN year >= 1990 AND year < 2000 THEN '1990s'
		WHEN year >= 2000 AND year < 2010 THEN '2000s'
		WHEN year >= 2010 AND year < 2020 THEN '2010s'
	END as decade,
    COUNT(*) as movies_released,
    ROUND(avg(score),2) as average_score
FROM dbo.movies
GROUP BY
	CASE
		WHEN year >= 1980 AND year < 1990 THEN '1980s'
		WHEN year >= 1990 AND year < 2000 THEN '1990s'
		WHEN year >= 2000 AND year < 2010 THEN '2000s'
		WHEN year >= 2010 AND year < 2020 THEN '2010s'
	END
ORDER BY decade ASC;

--------------------------------------------------------------------------------

/* Because the decade column will be integral to the analysis that follows, the following statement was used */

ALTER TABLE dbo.movies
ADD decade VARCHAR(10);

UPDATE dbo.movies
SET decade = CAST((year / 10) * 10 AS VARCHAR(4)) + 's';


-- Question 4: What are the three most profitable films during this period?
SELECT TOP 3
    name,
    gross - budget AS profit
FROM dbo.movies
WHERE budget IS NOT NULL 
AND gross IS NOT NULL
ORDER BY profit DESC;


-- Question 5: Which film has the longest runtime and what is its runtime?
SELECT
    name,
    runtime
FROM dbo.movies
WHERE runtime = (SELECT MAX(runtime) FROM dbo.movies);


-- Question 6: Identify all films whose titles contain the word 'Death'.
SELECT 
    name
FROM dbo.movies
WHERE name LIKE '%death%';


-- Question 7: Identify all films that start with the letter 'A'
SELECT
    name
FROM dbo.movies
WHERE name like 'A%';


-- Question 8: What is the average movie runtime in each decade rounded to two decimal places?
SELECT
    decade,
    ROUND(avg(runtime),2) AS avg_runtime
FROM dbo.movies
GROUP BY decade
ORDER BY decade ASC;


-- Question 9: Who are the top five stars across the entire period and how many films have they starred in?
SELECT TOP 5
    star,
    COUNT(*) as movies_starred_in
FROM dbo.movies
WHERE star IS NOT NULL 
GROUP BY star
ORDER BY movies_starred_in DESC


-- Question 10: How many different stars have there been in each decade?
SELECT
    decade,
    COUNT(DISTINCT star) AS distinct_stars
FROM dbo.movies
GROUP BY decade
ORDER BY decade ASC


-- Question 11: Who are the most frequently featured stars in each decade and how many films did each star appear in?
With star_ranking_cte AS
(
SELECT
    decade,
    star,
    COUNT(*) AS movies_starred_in,
    RANK() OVER (PARTITION BY decade ORDER BY COUNT(*) DESC) AS rank
FROM dbo.movies
WHERE star IS NOT NULL
GROUP BY decade, star
)

SELECT
    decade,
    star,
    movies_starred_in
FROM star_ranking_cte
WHERE rank = 1;


-- Question 12: Which films had the highest gross box office revenue in each decade?
With gross_revenue_ranking_cte AS
(
SELECT
    decade,
    name,
    gross,
    RANK() OVER (PARTITION BY decade ORDER BY gross DESC) as rank
FROM dbo.movies
WHERE gross IS NOT NULL 
)

SELECT
    decade,
    name,
    gross
FROM gross_revenue_ranking_cte
WHERE rank = 1;


-- Question 13: Which film incurred the greatest financial loss based on its budget and gross revenue? Who directed it and which company produced it?
SELECT TOP 1
    name,
    director,
    company,
    budget - gross AS loss_amount
FROM dbo.movies
WHERE budget > gross 
AND budget IS NOT NULL 
AND gross IS NOT NULL
ORDER BY loss_amount DESC;


-- Question 14: Which three actors have generated the highest combined box office revenue during this period and how much has each grossed (in billions)?
SELECT TOP 3
    star,
    CONCAT(ROUND(SUM(gross) / 1000000000.0,2), ' ', 'billion') AS gross_revenue
FROM dbo.movies
GROUP BY star
ORDER BY SUM(gross) DESC;


-- Question 15: Identify all films in which the same person served as director, star and writer. Only include films whose gross revenue was at least equal to their production budget.
SELECT
    name,
    director,
    writer,
    star
FROM dbo.movies
WHERE director = writer
AND writer = star 
AND gross >= budget
AND star IS NOT NULL
AND gross IS NOT NULL;


-- Question 16: Which five production companies have the highest average movie ratings? Only include companies that have released at least 10 films during this period?
SELECT TOP 5
    company,
    ROUND(AVG(score),2) AS avg_rating,
    COUNT(*) as films_produced
FROM dbo.movies
GROUP BY company 
HAVING COUNT(*) >= 10
ORDER BY avg_rating DESC;


-- Question 17: List all directors who directed multiple films within the same calendar year.
SELECT
    director,
    year,
    COUNT(*) AS movies_directed
FROM dbo.movies
WHERE director IS NOT NULL
GROUP BY director, year
HAVING COUNT(*) > 1
ORDER BY year ASC, movies_directed DESC;


-- Question 18: What is the average runtime of films produced in each country? Only include countries that have released at least 50 films during this period.
SELECT
    country,
    ROUND(AVG(runtime),2) AS average_runtime_mins
FROM dbo.movies
GROUP BY country
HAVING COUNT(*) >= 50
ORDER BY average_runtime_mins DESC;


-- Question 19: Identify all directors who have directed at least one film in every decade
SELECT
    director,
    COUNT(DISTINCT decade) as decades_active
FROM dbo.movies
WHERE director IS NOT NULL 
GROUP BY director
HAVING COUNT(DISTINCT decade) = (SELECT COUNT(DISTINCT decade) FROM dbo.movies);


-- Question 20: How many short (90 minutes or less), mid-length (91–150 minutes) and long (More than 150 minutes) films were released in each decade?
SELECT
    decade,
    COUNT(CASE WHEN runtime <= 90 THEN 1 END) AS short_movie,
    COUNT(CASE WHEN runtime > 90 AND runtime <= 150 THEN 1 END) AS mid_length_movie,
    COUNT(CASE WHEN runtime > 150 THEN 1 END) AS long_movie
FROM dbo.movies
GROUP BY decade
ORDER BY decade ASC;


-- Question 21: Which 3 genres have the highest number of films that incurred a financial loss and what is their loss rate?
With loss_count_cte AS
(
SELECT
    genre,
    COUNT(*) AS loss_count
FROM dbo.movies
WHERE budget > gross
AND budget IS NOT NULL AND gross IS NOT NULL 
GROUP BY genre
),
total_count_cte AS
(
SELECT
    genre,
    COUNT(*) AS total_count
FROM dbo.movies
WHERE budget IS NOT NULL AND gross IS NOT NULL 
GROUP BY genre
)

SELECT TOP 3
loss_count_cte.genre,
loss_count_cte.loss_count,
total_count_cte.total_count,
ROUND(100.0 * loss_count_cte.loss_count / total_count_cte.total_count,2) AS loss_rate
FROM loss_count_cte
JOIN total_count_cte ON loss_count_cte.genre = total_count_cte.genre
GROUP BY loss_count_cte.genre, loss_count_cte.loss_count, total_count_cte.total_count
ORDER BY loss_count_cte.loss_count DESC;


-- Question 22: Which directors have the highest average movie ratings, considering only directors who have directed at least 10 films during this period?
SELECT
    director,
    ROUND(avg(score),2) AS average_rating
FROM dbo.movies
GROUP BY director
HAVING COUNT(*) >= 10 
ORDER BY average_rating DESC;


-- Question 23: For films released in 1985, calculate the cumulative average rating, ordered alphabetically by movie title.
SELECT
    name,
    score,
    ROUND(AVG(score) OVER (ORDER BY name ASC),2) AS cumulative_avg_rating
FROM dbo.movies
WHERE year = 1985;


-- Question 24: What are the median and mode movie runtimes across the entire dataset?
SELECT DISTINCT
    PERCENTILE_CONT(0.5)
    WITHIN GROUP (ORDER BY runtime ASC) OVER () AS median_runtime
FROM dbo.movies
WHERE runtime IS NOT NULL;

SELECT TOP 1
    runtime AS mode_runtime,
    COUNT(*) AS frequency
FROM dbo.movies
GROUP BY runtime
ORDER BY frequency DESC;


-- Question 25: What was the year-on-year growth rate in total gross box office revenue for each year of the 2010s?
SELECT
year,
SUM(gross),
LAG(SUM(gross)) OVER (ORDER BY year ASC),
ROUND(100.0 * ((SUM(gross) - LAG(SUM(gross)) OVER (ORDER BY year ASC)) / LAG(SUM(gross)) OVER (ORDER BY year ASC)),2) AS year_on_year_growth_percent
FROM dbo.movies
WHERE decade = '2010s'
GROUP BY year
ORDER BY year ASC