SELECT * 
FROM country,league

SELECT DISTINCT season
FROM match
ORDER BY season

SELECT *
FROM match

--Which 2 teams have the highest sum of goals scored in all their face-offs with each other
WITH TT AS(
	SELECT 	m.away_team_api_id AS AT_id,
		SUM(home_team_goal + away_team_goal) AS Match_goal,
		team_long_name AS home_team_name
	FROM match m
	LEFT JOIN team t ON home_team_api_id = team_api_id
	GROUP BY AT_id, home_team_name
	ORDER BY Match_goal DESC
	
)
SELECT home_team_name, team_long_name AS away_team_name, match_goal
FROM TT
LEFT JOIN team t ON at_id = team_api_id
ORDER BY match_goal DESC
LIMIT 1

-- 
SELECT *
FROM player_attributes

--Alter birthday (text) column in player table to date format
ALTER TABLE player 
ALTER COLUMN birthday SET DATA TYPE date
      USING birthday::date;
	  
ALTER TABLE match 
ALTER COLUMN date SET DATA TYPE date
      USING date::date;

SELECT *, date_part('year', AGE('2011-08-13', birthday)) AS age --Calculate age for 2011/12 season
FROM player

SELECT sss.*, m.season
FROM (
	SELECT DISTINCT player_name, date_part('year', AGE('2011-08-13', birthday)) AS age, overall_rating
	FROM player
	LEFT JOIN player_attributes 
		ON player.player_api_id = player_attributes.player_api_id) SSS
LEFT JOIN match m
ON 1=1

SELECT 	*
FROM match

-- Q2
WITH fola AS(
SELECT season, 
	UNNEST(ARRAY[home_player_1, home_player_2, home_player_3, home_player_4, home_player_5,
				home_player_6, home_player_7, home_player_8, home_player_9, home_player_10,
				home_player_11, away_player_1, away_player_2, away_player_3, away_player_4,
				away_player_5, away_player_6, away_player_7,away_player_8, away_player_9,
				away_player_10, away_player_11]) AS id
FROM match
WHERE season = '2011/2012' AND date BETWEEN '2011-08-13' AND '2012-05-13'
ORDER BY season)
SELECT player_name, age, AVG(overall_rating) AS avg_overall_rating, season  
FROM fola
LEFT JOIN 
	(SELECT DISTINCT player_name, player.player_api_id, date_part('year', AGE('2011-08-13', birthday)) AS age, overall_rating
	FROM player
	LEFT JOIN player_attributes 
		ON player.player_api_id = player_attributes.player_api_id) SSS
ON id = player_api_id
WHERE player_name IS NOT NULL AND age <= 21
GROUP BY player_name, age, season
ORDER BY avg_overall_rating DESC;

--Q3
SELECT *
FROM match

SELECT t.team_long_name AS team_name,
		SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 3
		WHEN m.home_team_goal = m.away_team_goal THEN 1
		ELSE 0
		END) AS total_point,
		SUM(m.home_team_goal) AS total_goal_scored,
		SUM(m.away_team_goal) AS total_goal_against, 
		SUM(m.home_team_goal - m.away_team_goal) AS total_goal_difference
FROM team t
INNER JOIN match m
	ON team_api_id = home_team_api_id
WHERE league_id = 1729 AND  season = '2010/2011'
GROUP BY team_name
ORDER BY total_point, total_goal_difference DESC;

--Q4
SELECT home_player_y4, home_player_y6, COUNT(match_api_id) AS matches
FROM match
WHERE home_player_y4 IS NOT NULL
GROUP BY home_player_y4, home_player_y6
ORDER BY matches DESC;

--Q5
SELECT t.team_long_name AS team_name,
		MAX(ta.chancecreationshooting) AS highest_chance_creation_shooting
FROM team t
LEFT JOIN team_attributes ta
	ON t.team_api_id = ta.team_api_id
WHERE ta.chancecreationshooting IS NOT NULL
GROUP BY team_name
ORDER BY highest_chance_creation_shooting DESC;

--Q6
SELECT p.player_name, AVG(pa.sprint_speed) AS sprint_speed_average
FROM player p
LEFT JOIN player_attributes pa
	ON pa.player_api_id = p.player_api_id
GROUP BY player_name
ORDER BY sprint_speed_average DESC
LIMIT 10;

--Q7
SELECT p.player_name, COUNT(m.match_api_id) AS appearance
FROM player p
LEFT JOIN match m
	ON m.home_player_1 = p.player_api_id
GROUP BY player_name
ORDER BY appearance DESC 
LIMIT 1;

--Q8
SELECT l.name, SUM(m.home_team_goal + m.away_team_goal) AS total_goals
FROM league l
INNER JOIN match m
	ON l.id = m.league_id
GROUP BY l.name
ORDER BY total_goals DESC;

--Q9
SELECT t.team_long_name, MIN(m.b365h) AS min_home_odds
FROM team t
LEFT JOIN match m
	ON m.home_team_api_id = t.team_api_id
GROUP BY team_long_name
ORDER BY min_home_odds ASC;

-- Create a median function
CREATE OR REPLACE FUNCTION _final_median(numeric[])
   RETURNS numeric AS
$$
   SELECT AVG(val)
   FROM (
     SELECT val
     FROM unnest($1) val
     ORDER BY 1
     LIMIT  2 - MOD(array_upper($1, 1), 2)
     OFFSET CEIL(array_upper($1, 1) / 2.0) - 1
   ) sub;
$$
LANGUAGE 'sql' IMMUTABLE;

CREATE AGGREGATE median(numeric) (
  SFUNC=array_append,
  STYPE=numeric[],
  FINALFUNC=_final_median,
  INITCOND='{}'
);

--Q10
WITH fola AS(
SELECT
	UNNEST(ARRAY[home_player_1, home_player_2, home_player_3, home_player_4, home_player_5,
				home_player_6, home_player_7, home_player_8, home_player_9, home_player_10,
				home_player_11, away_player_1, away_player_2, away_player_3, away_player_4,
				away_player_5, away_player_6, away_player_7,away_player_8, away_player_9,
				away_player_10, away_player_11]) AS id
FROM match
)
SELECT player_name, 
		AVG(overall_rating) AS avg_overall_rating, 
		MAX(overall_rating) AS max_overall_rating,
		MIN(overall_rating) AS min_overall_rating,
		MEDIAN(overall_rating) AS median_overall_rating
FROM fola
LEFT JOIN 
	(SELECT DISTINCT player_name, 
	 		player.player_api_id,
	 		overall_rating
	FROM player
	LEFT JOIN player_attributes 
		ON player.player_api_id = player_attributes.player_api_id) SSS
ON id = player_api_id
WHERE player_name LIKE 'Lionel Messi%' OR player_name LIKE 'Cristiano Ronaldo%'
GROUP BY player_name
;

--Q11
WITH regression_table AS (
	SELECT DISTINCT player_name, finishing, overall_rating
	FROM match m
	INNER JOIN
		(SELECT p.player_name, pa.player_api_id, pa.finishing, pa.overall_rating
		FROM player p
		LEFT JOIN player_attributes pa ON p.player_api_id = pa.player_api_id) sss
	ON home_player_9 = player_api_id
	WHERE home_player_9 IS NOT NULL
)
SELECT 'Y=' || regr_slope(finishing, overall_rating) || 
'X+' || regr_intercept(finishing, overall_rating) || 
' is the regression formula with R-squared value of ' || regr_r2(finishing, overall_rating)
AS  regression_formula_output
FROM regression_table;
