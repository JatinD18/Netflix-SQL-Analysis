# 🎬 Netflix Content Analysis — SQL Portfolio Project

## Overview
End-to-end SQL analysis of **5,850+ Netflix titles** and **77,800+ cast/crew credits** 
to extract actionable business insights on content strategy, genre performance, 
and global production trends.

## Tools Used
- MySQL 8.0
- Python (pandas, SQLAlchemy) for data import
- Kaggle Dataset: [Netflix TV Shows and Movies](https://www.kaggle.com/datasets/victorsoeiro/netflix-tv-shows-and-movies)

## Key SQL Skills Demonstrated
- Data Cleaning: `NULLIF`, `TRIM`, `CAST`, `COALESCE`
- Feature Engineering: `SUBSTRING_INDEX`, `REPLACE` for array parsing
- Aggregations: `GROUP BY`, `HAVING`, `SUM`, `AVG`, `COUNT`
- Conditional Logic: `CASE WHEN` for bucketing
- JOINs: Multi-table joins between titles and credits
- String Functions: `GROUP_CONCAT`, `LIKE` filtering

## Top 5 Insights
1. Netflix shifted from Movies → TV Shows after 2015
2. Drama & Comedy dominate volume; Documentary scores highest
3. Standard-length movies (101-120 min) get best ratings
4. US leads production; KR, JP, IN are fastest-growing
5. TV-MA content dominates = adult-first strategy

## How to Run
1. Install MySQL 8.0
2. Run `netflix_analysis.sql` in MySQL Workbench
3. Execute all sections top-to-bottom

## Author
Jatin Naresh Dolas — [Jatin Dolas - Linkedin](linkedin.com/in/jatin-dolas) - [Jatin Dolas - GitHub](github.com/JatinD18)
