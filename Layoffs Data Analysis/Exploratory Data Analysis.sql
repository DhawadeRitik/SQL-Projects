USE world_layoffs;


-- =======================  EXPLORATORY DATA ANALYSIS  ===============================================
SELECT * FROM layoffs_staging2;

SELECT * FROM layoffs_staging2
WHERE industry = 'Healthcare';

SELECT DISTINCT industry 
FROM layoffs_staging2;

-- See the max laid off 
SELECT MAX(total_laid_off) FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off = (SELECT MAX(total_laid_off) FROM layoffs_staging2);

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = (SELECT MAX(percentage_laid_off) FROM layoffs_staging2);

-- Companies with PERCENTAGE_LAID_OFF IS 1 means total laid off 
SELECT company , location , industry , total_laid_off, country , funds_raised_millions
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;


-- Company wise total laid offs 
SELECT company , SUM(total_laid_off) as Total_Laid_Off
FROM layoffs_staging2 
GROUP BY company
ORDER BY 2 DESC;

-- date range 
SELECT MIN(`date`) start_date , MAX(`date`) end_date
FROM layoffs_staging2;

-- See Which Year has most laid off 
WITH year_wise_laid_off AS (
SELECT 
YEAR(`date`) AS Years,
SUM(total_laid_off) total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
) 
SELECT Years, total_laid_off,
   CONCAT(ROUND(total_laid_off * 100.0 / SUM(total_laid_off) OVER (), 2), '%') AS pct_laid_off
 FROM year_wise_laid_off
WHERE Years IS NOT NULL
GROUP BY Years, total_laid_off;

-- Industry Wise Laid Off by year wise
SELECT 
		industry ,
        YEAR(`date`) years,
		SUM(total_laid_off) AS total_laid_off
FROM 
layoffs_staging2
GROUP BY industry, YEAR(`date`)
ORDER BY total_laid_off DESC;

-- country wise laid off 
SELECT 
		country , 
		SUM(total_laid_off) AS total_laid_off
FROM 
layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;



-- ============================================ Different Unique Country ========================================================

CREATE VIEW unique_country AS 
SELECT DISTINCT country FROM layoffs_staging2;
SELECT  * FROM unique_country;

-- ============================================= Different / Unique Company ===================================================

CREATE VIEW different_company AS 
SELECT DISTINCT company FROM layoffs_staging2;
SELECT * FROM different_company;

-- ============================================= Different / Unique Industry =====================================================

CREATE VIEW unique_industry AS
SELECT DISTINCT industry FROM layoffs_staging2
WHERE industry IS NOT NULL;
SELECT * FROM unique_industry;

-- ======================================== Company Wise Layoff ==================================================================

CREATE VIEW company_wise_layoff AS
SELECT company as Company , SUM(total_laid_off) as Total_Layoff
FROM layoffs_staging2 
GROUP BY company
ORDER BY 2 DESC;

-- ======================================= Company Layoff for Perticular Year =================================================================
-- Year wise laid of by country 
CREATE VIEW yearly_laid_off_by_country AS
WITH country_laid_off_year AS (
SELECT 
    YEAR(`date`) AS years, 
    country ,
    SUM(total_laid_off) AS laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`), country 
ORDER BY laid_off DESC
) 
SELECT country , years , laid_off
FROM country_laid_off_year
WHERE years IS NOT NULL
AND laid_off IS NOT NULL 
ORDER BY country , years;
SELECT * FROM yearly_laid_off_by_country;

-- ======================================================  Top 5 country with Most laidoff ============================================
CREATE VIEW Top_5_country_by_laidoff AS
SELECT 
country , SUM(total_laid_off) as laid_off 
FROM layoffs_staging2
GROUP BY country
ORDER BY laid_off DESC
LIMIT 5;
SELECT * FROM Top_5_country_by_laidoff;

-- ============================================================== Industry Wise layoff ====================================================
CREATE VIEW top_10_industry_by_layoff AS 
SELECT 
industry AS Industry, SUM(total_laid_off) AS 'Total Layoff'
FROM layoffs_staging2
GROUP BY industry 
ORDER BY 2 DESC
LIMIT 10;
SELECT * FROM top_10_industry_by_layoff;



SELECT * FROM layoffs_staging2;




 
WITH year_wise_laid_off AS (
SELECT 
YEAR(`date`) AS Years,
SUM(total_laid_off) total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
) 
SELECT Years, total_laid_off,
   CONCAT(ROUND(total_laid_off * 100.0 / SUM(total_laid_off) OVER (), 2), '%') AS pct_laid_off
 FROM year_wise_laid_off
WHERE Years IS NOT NULL
GROUP BY Years, total_laid_off;
