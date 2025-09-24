SELECT * FROM world_layoffs.layoffs;

SELECT * FROM layoffs_data;

-- Data Cleaning 

-- 1. Remove Duplicates 
-- 2. Standardize the Data 
-- 3. Null Values or Blanlk Values 
-- 4. Remove Any Unnecessary Columns 

-- CREATE TABLE SAME AS layoffs_data
CREATE TABLE layoffs_staging
LIKE layoffs_data;

-- INSERT THE DATA INTO layoff_staging FROM layoffs_data
INSERT layoffs_staging
SELECT * FROM layoffs_data;

-- 1. REMOVE DUPLICATES 
SELECT * ,
ROW_NUMBER() OVER( PARTITION BY company, industry, total_laid_off, `date`) AS row_num
FROM layoffS_staging;

-- Find the duplicate records
WITH duplicate_records AS (
SELECT * ,
ROW_NUMBER()  OVER( PARTITION BY 
							company, location, industry, 
                            total_laid_off, `date`, stage, 
                            country, funds_raised_millions
					) AS row_num
FROM layoffs_staging
) 
SELECT * 
FROM duplicate_records 
WHERE row_num > 1;

-- This is used to find the schema structure of the table
SHOW CREATE TABLE layoffs_staging;
CREATE TABLE `layoffs_staging2` (
   `company` text,
   `location` text,
   `industry` text,
   `total_laid_off` double DEFAULT NULL,
   `percentage_laid_off` double DEFAULT NULL,
   `date` text,
   `stage` text,
   `country` text,
   `funds_raised_millions` double DEFAULT NULL,
   row_num  INT
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT * ,
ROW_NUMBER()  OVER( PARTITION BY 
							company, location, industry, 
                            total_laid_off, `date`, stage, 
                            country, funds_raised_millions
					) AS row_num
FROM layoffs_staging;

SELECT * FROM layoffs_staging2
WHERE row_num > 1;

-- DELETE THE DUPLICATE VALUES FROM THE layoffs_staging2
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- 2. Standardize the Data 

-- company column
SELECT company , TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- industry column 
SELECT industry , TRIM(industry)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET industry = TRIM(industry);

SELECT DISTINCT(industry)
FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging2
WHERE industry LIKE "Crypto%";

-- industry columns have values Crypro nad Crypto Currency, Both are same ,
-- Convert the Crypto Currency to Crypto 
UPDATE layoffs_staging2 
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

-- validate change 
SELECT * 
FROM layoffs_staging2
WHERE industry LIKE "Crypto%";

SELECT DISTINCT(industry)
FROM layoffs_staging2;


-- check location columns 
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- check counrty column 
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- We have an issue with United States --> United States and United States.
SELECT * 
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- Update United States. to United States 
UPDATE layoffs_staging2 
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE "United States%"; 
-- =================================== SAME AS ABOVE 
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE "United States.";

-- validate change 
SELECT DISTINCT country 
FROM layoffs_staging2;

-- Change the date column from text to date 
SELECT `date`,
str_to_date(`date`, "%m/%d/%Y")
FROM layoffs_staging2;

-- this change the formate of the column from text tp date formate but not and datatype 
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, "%m/%d/%Y");

-- Now change the datatype of the column
ALTER  TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. NULL VALUES 
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL ;

-- industry 
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR  industry = ' ';

SELECT t1.industry , t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2 
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = " ")
AND  t2.industry IS NOT NULL ;

-- Update the industry 
UPDATE layoffs_staging2 t1 
	JOIN layoffs_staging2 AS t2 
	ON t1.company = t2.company
SET t1.industry = t2.industry 
WHERE (t1.industry IS NULL OR t1.industry = " ")
AND  t2.industry IS NOT NULL ;

-- Validate the update 
SELECT t1.industry , t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2 
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = " ")
AND  t2.industry IS NOT NULL ;





