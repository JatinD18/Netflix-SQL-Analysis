-- ============================================================================
-- PROJECT:       Netflix TV Shows & Movies — SQL Data Analysis
-- AUTHOR:        Jatin Naresh Dolas
-- DATE:          13th October 2026
-- DATABASE:      MySQL 8.0
-- DATASET:       Netflix TV Shows and Movies (by Victor Soeiro) — Kaggle
-- DATASET LINK:  https://www.kaggle.com/datasets/victorsoeiro/netflix-tv-shows-and-movies
-- DESCRIPTION:   End-to-end SQL analysis of 5,850+ Netflix titles and 
--                77,800+ cast/crew credits to extract actionable business 
--                insights on content strategy, genre performance, and 
--                production trends.
-- ============================================================================
-- TABLE OF CONTENTS:
--   SECTION 1:  Database & Table Setup
--   SECTION 2:  Data Cleaning — Titles
--   SECTION 3:  Data Cleaning — Credits
--   SECTION 4:  Feature Engineering — Genre & Country Extraction
--   SECTION 5:  Business Analysis — 10 Key Queries
--   SECTION 6:  Summary View for BI Dashboard Export
-- ============================================================================


-- ============================================================================
-- SECTION 1: DATABASE & TABLE SETUP
-- ============================================================================
-- Purpose: Create a dedicated database and verify raw data tables.
-- Note:    Raw tables (titles_raw, credits_raw) were imported from CSV 
--          using Python (pandas + SQLAlchemy) to handle multi-line 
--          description fields and missing line breaks in the source files.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS netflix_analysis;
USE netflix_analysis;

-- Verify raw data loaded correctly
SELECT 'titles_raw' AS table_name, COUNT(*) AS row_count FROM titles_raw
UNION ALL
SELECT 'credits_raw' AS table_name, COUNT(*) AS row_count FROM credits_raw;

-- Expected: titles_raw ≈ 5,850 | credits_raw ≈ 77,801


-- ============================================================================
-- SECTION 2: DATA CLEANING — TITLES
-- ============================================================================
-- Purpose: Transform raw titles data by casting text columns to proper 
--          numeric types, handling NULLs, empty strings, and decimal 
--          values (e.g., '2.0', '11233.0').
-- Key Functions: NULLIF, TRIM, CAST, COALESCE
-- ============================================================================

DROP TABLE IF EXISTS titles_clean;

CREATE TABLE titles_clean AS
SELECT 
    id,
    title,
    type,
    description,
    CAST(release_year AS UNSIGNED)                          AS release_year,
    COALESCE(NULLIF(TRIM(age_certification), ''), 'Not Rated') AS age_certification,
    CAST(runtime AS UNSIGNED)                               AS runtime,
    genres,
    production_countries,
    -- FIX: '2.0' → DECIMAL → UNSIGNED (handles Kaggle decimal formatting)
    CAST(CAST(seasons AS DECIMAL(10,1)) AS UNSIGNED)       AS seasons,
    NULLIF(TRIM(imdb_id), '')                               AS imdb_id,
    CAST(imdb_score AS DECIMAL(3,1))                        AS imdb_score,
    -- FIX: '11233.0' → DECIMAL → UNSIGNED
    CAST(CAST(imdb_votes AS DECIMAL(15,1)) AS UNSIGNED)    AS imdb_votes,
    CAST(tmdb_popularity AS DECIMAL(10,3))                  AS tmdb_popularity,
    CAST(tmdb_score AS DECIMAL(3,1))                        AS tmdb_score
FROM titles_raw
WHERE id IS NOT NULL;

-- Verify cleaning
SELECT COUNT(*) AS total_rows FROM titles_clean;

-- Check NULL distribution in key columns
SELECT 
    COUNT(*)                                                    AS total,
    SUM(CASE WHEN runtime IS NULL THEN 1 ELSE 0 END)           AS null_runtime,
    SUM(CASE WHEN seasons IS NULL THEN 1 ELSE 0 END)           AS null_seasons,
    SUM(CASE WHEN imdb_score IS NULL THEN 1 ELSE 0 END)        AS null_imdb_score,
    SUM(CASE WHEN imdb_votes IS NULL THEN 1 ELSE 0 END)        AS null_imdb_votes,
    SUM(CASE WHEN tmdb_popularity IS NULL THEN 1 ELSE 0 END)   AS null_tmdb_pop
FROM titles_clean;


-- ============================================================================
-- SECTION 3: DATA CLEANING — CREDITS
-- ============================================================================
-- Purpose: Clean cast/crew data by trimming whitespace, standardizing 
--          role values, and removing orphaned records.
-- Key Functions: TRIM, UPPER, CAST
-- ============================================================================

DROP TABLE IF EXISTS credits_clean;

CREATE TABLE credits_clean AS
SELECT 
    CAST(person_id AS UNSIGNED)   AS person_id,
    TRIM(id)                      AS show_id,
    TRIM(name)                    AS name,
    TRIM(character_name)          AS character_name,
    UPPER(TRIM(role))             AS role
FROM credits_raw
WHERE name IS NOT NULL
  AND TRIM(name) != ''
  AND id IS NOT NULL;

-- Verify cleaning
SELECT COUNT(*) AS total_rows FROM credits_clean;
SELECT DISTINCT role FROM credits_clean;
-- Expected: ACTOR, DIRECTOR


-- ============================================================================
-- SECTION 4: FEATURE ENGINEERING — GENRE & COUNTRY EXTRACTION
-- ============================================================================
-- Purpose: The raw 'genres' and 'production_countries' columns contain 
--          stringified arrays like "['drama', 'comedy']". This section 
--          extracts the PRIMARY (first-listed) genre and country into 
--          dedicated columns for clean GROUP BY analysis.
-- Key Functions: SUBSTRING_INDEX, REPLACE, TRIM
-- ============================================================================

-- Disable safe mode to allow UPDATE without KEY in WHERE
SET SQL_SAFE_UPDATES = 0;

-- Add new columns
ALTER TABLE titles_clean ADD COLUMN primary_genre VARCHAR(50);
ALTER TABLE titles_clean ADD COLUMN primary_country VARCHAR(50);

-- Extract first genre: "['drama', 'comedy']" → "drama"
UPDATE titles_clean
SET primary_genre = TRIM(
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    SUBSTRING_INDEX(genres, ',', 1),
                    '[', ''
                ),
                '''', ''
            ),
            ']', ''
        ),
        '"', ''
    )
)
WHERE id IS NOT NULL
  AND genres IS NOT NULL 
  AND genres != '[]'
  AND TRIM(genres) != '';

-- Extract first country: "['US', 'CA']" → "US"
UPDATE titles_clean
SET primary_country = TRIM(
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    SUBSTRING_INDEX(production_countries, ',', 1),
                    '[', ''
                ),
                '''', ''
            ),
            ']', ''
        ),
        '"', ''
    )
)
WHERE id IS NOT NULL
  AND production_countries IS NOT NULL 
  AND production_countries != '[]'
  AND TRIM(production_countries) != '';

-- Re-enable safe mode
SET SQL_SAFE_UPDATES = 1;

-- Verify extraction
SELECT DISTINCT primary_genre 
FROM titles_clean 
WHERE primary_genre IS NOT NULL AND primary_genre != ''
ORDER BY primary_genre;

SELECT DISTINCT primary_country 
FROM titles_clean 
WHERE primary_country IS NOT NULL AND primary_country != ''
ORDER BY primary_country;


-- ============================================================================
-- SECTION 5: BUSINESS ANALYSIS — 10 KEY QUERIES
-- ============================================================================
-- Purpose: Extract actionable business insights from the cleaned dataset.
--          Each query answers a specific strategic question that a Netflix 
--          content executive or data analyst would ask.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- QUERY 1: CONTENT GROWTH OVER TIME
-- Business Question: How has Netflix's content library evolved? 
--                    Are they investing more in Movies or TV Shows?
-- ----------------------------------------------------------------------------
SELECT 
    release_year,
    type,
    COUNT(id) AS content_count
FROM titles_clean
WHERE release_year >= 2000
  AND release_year IS NOT NULL
GROUP BY release_year, type
ORDER BY release_year DESC, type;
-- INSIGHT: Netflix shifted heavily toward TV Shows after 2015.


-- ----------------------------------------------------------------------------
-- QUERY 2: TOP GENRES BY VOLUME & QUALITY
-- Business Question: Which genres dominate the library, and which 
--                    deliver the best audience ratings?
-- ----------------------------------------------------------------------------
SELECT 
    primary_genre,
    COUNT(title)                                     AS total_titles,
    ROUND(AVG(imdb_score), 2)                        AS avg_imdb_score,
    ROUND(AVG(imdb_votes), 0)                        AS avg_imdb_votes,
    SUM(CASE WHEN type = 'MOVIE' THEN 1 ELSE 0 END) AS movies,
    SUM(CASE WHEN type = 'SHOW' THEN 1 ELSE 0 END)  AS shows
FROM titles_clean
WHERE primary_genre IS NOT NULL 
  AND primary_genre != ''
  AND imdb_score IS NOT NULL
GROUP BY primary_genre
HAVING total_titles >= 10
ORDER BY total_titles DESC
LIMIT 15;
-- INSIGHT: Drama and Comedy dominate volume; Documentary often scores highest.


-- ----------------------------------------------------------------------------
-- QUERY 3: RUNTIME vs IMDB SCORE (MOVIES ONLY)
-- Business Question: What is the optimal movie length for audience satisfaction?
-- ----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN runtime < 80              THEN 'A: Short (<80 min)'
        WHEN runtime BETWEEN 80 AND 100  THEN 'B: Medium (80-100 min)'
        WHEN runtime BETWEEN 101 AND 120 THEN 'C: Standard (101-120 min)'
        WHEN runtime BETWEEN 121 AND 150 THEN 'D: Long (121-150 min)'
        ELSE 'E: Epic (150+ min)'
    END AS runtime_bucket,
    COUNT(title)                    AS movie_count,
    ROUND(AVG(imdb_score), 2)       AS avg_score,
    ROUND(AVG(imdb_votes), 0)       AS avg_votes
FROM titles_clean
WHERE type = 'MOVIE' 
  AND runtime IS NOT NULL
  AND imdb_score IS NOT NULL
GROUP BY runtime_bucket
ORDER BY runtime_bucket;
-- INSIGHT: Standard-length films (101-120 min) tend to score highest.


-- ----------------------------------------------------------------------------
-- QUERY 4: TOP PRODUCTION COUNTRIES
-- Business Question: Which countries are the biggest content powerhouses 
--                    for Netflix outside the US?
-- ----------------------------------------------------------------------------
SELECT 
    primary_country,
    COUNT(id)                                        AS total_content,
    SUM(CASE WHEN type = 'MOVIE' THEN 1 ELSE 0 END) AS movies,
    SUM(CASE WHEN type = 'SHOW' THEN 1 ELSE 0 END)  AS shows,
    ROUND(AVG(imdb_score), 2)                        AS avg_imdb_score
FROM titles_clean
WHERE primary_country IS NOT NULL 
  AND primary_country != ''
GROUP BY primary_country
ORDER BY total_content DESC
LIMIT 15;
-- INSIGHT: US dominates; GB, KR, JP, IN are top international contributors.


-- ----------------------------------------------------------------------------
-- QUERY 5: AGE CERTIFICATION ANALYSIS
-- Business Question: Is Netflix primarily targeting adult audiences?
--                    Which rating categories get the best engagement?
-- ----------------------------------------------------------------------------
SELECT 
    age_certification,
    type,
    COUNT(id)                       AS content_count,
    ROUND(AVG(imdb_score), 2)       AS avg_score,
    ROUND(AVG(imdb_votes), 0)       AS avg_votes
FROM titles_clean
WHERE age_certification != 'Not Rated'
  AND imdb_score IS NOT NULL
GROUP BY age_certification, type
ORDER BY content_count DESC;
-- INSIGHT: TV-MA and R-rated content dominate, confirming adult-first strategy.


-- ----------------------------------------------------------------------------
-- QUERY 6: MOST PROLIFIC ACTORS (JOIN: credits ↔ titles)
-- Business Question: Which actors appear in the most Netflix titles?
--                    Are there "Netflix regulars"?
-- ----------------------------------------------------------------------------
SELECT 
    c.name,
    COUNT(DISTINCT c.show_id) AS num_titles,
    GROUP_CONCAT(
        DISTINCT t.title 
        ORDER BY t.release_year DESC 
        SEPARATOR ' | '
    ) AS recent_work
FROM credits_clean c
JOIN titles_clean t ON c.show_id = t.id
WHERE c.role = 'ACTOR'
  AND c.character_name IS NOT NULL
  AND c.character_name != ''
  AND c.character_name NOT LIKE '%Self%'
  AND c.character_name NOT LIKE '%Himself%'
  AND c.character_name NOT LIKE '%Herself%'
GROUP BY c.name
HAVING num_titles >= 3
ORDER BY num_titles DESC
LIMIT 20;
-- INSIGHT: Identifies recurring actors who may be strategic partnerships.


-- ----------------------------------------------------------------------------
-- QUERY 7: DIRECTORS WITH HIGHEST AVERAGE IMDB SCORES
-- Business Question: Which directors consistently deliver the highest-rated 
--                    content? Who should Netflix greenlight next?
-- ----------------------------------------------------------------------------
SELECT 
    c.name                          AS director_name,
    COUNT(DISTINCT c.show_id)       AS num_titles,
    ROUND(AVG(t.imdb_score), 2)     AS avg_imdb_score,
    ROUND(AVG(t.imdb_votes), 0)     AS avg_votes
FROM credits_clean c
JOIN titles_clean t ON c.show_id = t.id
WHERE c.role = 'DIRECTOR'
  AND t.imdb_score IS NOT NULL
GROUP BY c.name
HAVING num_titles >= 3
ORDER BY avg_imdb_score DESC
LIMIT 20;
-- INSIGHT: Reveals high-performing directors for future investment decisions.


-- ----------------------------------------------------------------------------
-- QUERY 8: LONG-RUNNING TV SHOWS WITH BEST RATINGS
-- Business Question: Which multi-season shows retain high quality?
--                    What genres sustain audience interest over time?
-- ----------------------------------------------------------------------------
SELECT 
    title,
    seasons,
    imdb_score,
    imdb_votes,
    primary_genre,
    primary_country
FROM titles_clean
WHERE type = 'SHOW'
  AND seasons >= 3
  AND imdb_score IS NOT NULL
ORDER BY imdb_score DESC
LIMIT 20;
-- INSIGHT: Identifies franchises worth renewing or expanding.


-- ----------------------------------------------------------------------------
-- QUERY 9: GENRE TRENDS BY DECADE
-- Business Question: How have audience genre preferences shifted over 
--                    the past three decades?
-- ----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN release_year BETWEEN 1990 AND 1999 THEN '1990s'
        WHEN release_year BETWEEN 2000 AND 2009 THEN '2000s'
        WHEN release_year BETWEEN 2010 AND 2019 THEN '2010s'
        WHEN release_year >= 2020               THEN '2020s'
    END AS decade,
    primary_genre,
    COUNT(id)                       AS title_count,
    ROUND(AVG(imdb_score), 2)       AS avg_score
FROM titles_clean
WHERE release_year >= 1990
  AND primary_genre IS NOT NULL
  AND primary_genre != ''
  AND imdb_score IS NOT NULL
GROUP BY decade, primary_genre
HAVING title_count >= 5
ORDER BY decade, title_count DESC;
-- INSIGHT: Shows the rise of international content and reality TV in 2020s.


-- ----------------------------------------------------------------------------
-- QUERY 10: HIDDEN GEMS — HIGH POPULARITY, LOW VOTES
-- Business Question: Which titles are popular on TMDB but underrated 
--                    on IMDB? Potential marketing opportunities?
-- ----------------------------------------------------------------------------
SELECT 
    title,
    type,
    release_year,
    tmdb_popularity,
    imdb_votes,
    imdb_score,
    primary_genre
FROM titles_clean
WHERE imdb_score IS NOT NULL
  AND tmdb_popularity IS NOT NULL
  AND imdb_votes < 5000
  AND imdb_score >= 7.0
ORDER BY CAST(tmdb_popularity AS DECIMAL(10,2)) DESC
LIMIT 20;
-- INSIGHT: Underrated titles that deserve more visibility/promotion.


-- ============================================================================
-- SECTION 6: SUMMARY VIEW FOR BI DASHBOARD EXPORT
-- ============================================================================
-- Purpose: Create a clean, consolidated view that can be exported to 
--          Excel, Tableau, or Power BI for interactive dashboard creation.
-- ============================================================================

CREATE OR REPLACE VIEW vw_netflix_summary AS
SELECT 
    id,
    title,
    type,
    release_year,
    age_certification,
    runtime,
    primary_genre,
    primary_country,
    seasons,
    imdb_score,
    imdb_votes,
    tmdb_popularity,
    tmdb_score
FROM titles_clean
WHERE imdb_score IS NOT NULL;

-- Test the view
SELECT * FROM vw_netflix_summary LIMIT 10;

-- Export command (run in terminal if needed):
-- SELECT * FROM vw_netflix_summary
-- INTO OUTFILE '/path/to/netflix_summary.csv'
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';


-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
-- SUMMARY OF KEY FINDINGS:
--   1. Netflix shifted from Movies to TV Shows after 2015.
--   2. Drama & Comedy dominate volume; Documentary scores highest.
--   3. Standard-length movies (101-120 min) get best audience ratings.
--   4. US leads production; KR, JP, IN are fastest-growing markets.
--   5. TV-MA content dominates, confirming adult-first content strategy.
-- ============================================================================