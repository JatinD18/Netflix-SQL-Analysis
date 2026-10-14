# 🎬 Netflix Content Strategy Analysis (SQL)

## 📊 Exploratory Data Analysis & Business Insights

Below are the key findings extracted from analyzing 5,800+ Netflix titles and 77,000+ cast/crew credits using MySQL.

---

### 1. Content Growth: The Shift from Movies to TV Shows
**Business Question:** How has Netflix's content library evolved over the last two decades?

![Content Growth over Time](Visualization/01_content_growth.png)

**💡 Key Insight:** 
While Netflix's library was heavily dominated by licensed Movies in the early 2010s, there is a massive strategic pivot starting around **2015-2016** toward producing and acquiring **TV Shows**. This aligns with Netflix's strategy to increase user retention through binge-watchable serialized content.

---

### 2. Genre Analysis: Volume vs. Quality
**Business Question:** Which genres dominate the library, and which actually satisfy the audience?

![Top Genres by Volume and IMDB Score](Visualization/02_genre_analysis.png)

**💡 Key Insight:** 
* **Drama** and **Comedy** make up the vast majority of the catalog (high volume).
* However, **Documentary** and **Animation** consistently yield the highest average IMDB scores. 
* *Recommendation:* Netflix should continue using Documentaries as "prestige" content to win awards and maintain high platform ratings, while using Dramas for mass-market volume.

---

### 3. The "Sweet Spot" for Movie Runtimes
**Business Question:** What is the optimal movie length for audience satisfaction?

![Runtime vs IMDB Score](Visualization/03_runtime_sweet_spot.png)

**💡 Key Insight:** 
Movies in the **Standard (101-120 min)** and **Medium (80-100 min)** buckets receive the highest average IMDB scores and the most votes. "Epic" movies (150+ mins) are rare and show a slight drop in average audience rating, suggesting modern streaming audiences prefer tighter, well-paced storytelling.
