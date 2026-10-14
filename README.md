# 🎬 Netflix Content Strategy Analysis — SQL & Power BI Portfolio Project

## 📌 Overview
End-to-end data analysis of **5,850+ Netflix titles** and **77,800+ cast/crew credits** to extract actionable business insights on content strategy, genre performance, and global production trends. 

This project demonstrates the full data analytics pipeline: from **wrangling messy raw data with Python**, to **advanced analytical querying in MySQL**, and finally **visual storytelling in Power BI**.

## 🛠️ Tools & Technologies Used
- **Database:** MySQL 8.0
- **Data Wrangling:** Python (Pandas, SQLAlchemy, Regex for CSV parsing)
- **Visualization:** Power BI (DAX, Calculated Columns, Conditional Formatting)
- **Dataset:** [Netflix TV Shows and Movies (Kaggle)](https://www.kaggle.com/datasets/victorsoeiro/netflix-tv-shows-and-movies)

---

## 📊 Power BI Dashboard & Business Insights

![Netflix Power BI Dashboard](https://github.com/JatinD18/Netflix-SQL-Analysis/blob/main/Visualization/netflix_powerbi_dashboard.png)

### Key Insights Uncovered:
1. **The Originals Shift:** Netflix aggressively pivoted from licensing Movies to producing original TV Shows post-2015 to maximize subscriber retention.
2. **The Genre Matrix:** While *Drama* and *Comedy* dominate sheer volume, *Documentaries* consistently punch above their weight, offering the highest average IMDB scores relative to production volume.
3. **The Runtime Sweet Spot:** Movies in the "Standard (101-120 min)" bracket yield the highest audience satisfaction, suggesting this is the optimal target length for future Netflix Original film investments.

📥 **[View the Interactive Dashboard PDF](https://github.com/JatinD18/Netflix-SQL-Analysis/blob/main/netflix_powerbi_dashboard.pdf)**

---

## 🧠 Key Technical Skills Demonstrated

### SQL (MySQL)
- **Data Cleaning:** Handled missing values and type casting using `NULLIF`, `TRIM`, `CAST`, and `COALESCE`.
- **Feature Engineering:** Parsed JSON-like string arrays (e.g., `['Drama', 'Crime']`) into primary genres using `SUBSTRING_INDEX` and `REPLACE`.
- **Aggregations & Logic:** Used `GROUP BY`, `HAVING`, `SUM`, `AVG`, and `CASE WHEN` to bucket movie runtimes and calculate decade trends.
- **Relational Joins:** Multi-table joins between `titles` and `credits` to identify top actors and directors.

### Python (Data Engineering)
- **Automated Data Ingestion:** Wrote a Python script using `pandas` and `SQLAlchemy` to bypass MySQL Workbench import limitations.
- **Regex Data Wrangling:** Used Regular Expressions (`re` module) to split and fix malformed CSV files where multi-line descriptions broke standard row delimiters.

### Power BI (Business Intelligence)
- **DAX Calculated Columns:** Created dynamic runtime buckets to allow for granular filtering.
- **Visual Hierarchy:** Applied conditional formatting and custom hex themes (Netflix Red `#E50914`) to guide stakeholder attention to key insights.

---

## 📂 Repository Structure
Netflix-SQL-Analysis/
│
├── data/ # Raw and cleaned CSV datasets
├── sql_scripts/ # MySQL scripts (Schema, Cleaning, Analysis)
├── python_scripts/ # Python CSV fixer & SQLAlchemy importer
├── visualizations/ # Power BI Dashboard screenshots & PDF exports
└── README.md # Project documentation


---

## 🚀 How to Run This Project
1. **Database Setup:** Install MySQL 8.0 and create a database named `netflix_analysis`.
2. **Data Import:** Run the Python script to clean the raw Kaggle CSVs and push them directly into MySQL.
3. **SQL Analysis:** Execute the scripts in the `sql_scripts/` folder sequentially to clean the data and generate business insights.
4. **Dashboard:** Open the Power BI file (or view the exported PDF in the `visualizations/` folder) to explore the interactive dashboard.

---

## 👤 Author
**Jatin Naresh Dolas**  
🔗 [LinkedIn](https://www.linkedin.com/in/jatin-dolas) | 💻 [GitHub](https://github.com/JatinD18)
