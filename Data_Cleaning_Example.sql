SET SQL_SAFE_UPDATES = 0;

SELECT *
FROM layoffs;

-- 1. Remove Duplicates

SELECT *,
ROW_NUMBER() OVER(
	partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
FROM layoffs_staging;

WITH duplicate_cta as
(
SELECT *,
ROW_NUMBER() OVER(
	partition by company, location,
    stage, country, funds_raised_millions, industry, total_laid_off, percentage_laid_off, `date`) as row_num
FROM layoffs_staging
)
select *
FROM duplicate_cta
where row_num > 1;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
	partition by company, location,
    stage, country, funds_raised_millions, industry, total_laid_off, percentage_laid_off, `date`) as row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num > 1
;

SELECT *
FROM layoffs_staging2
;

-- 2. Standardize the Data

SELECT company, TRIM(company)
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT *
FROM layoffs_staging2
WHERE industry LIKE "Crypto%"
;

UPDATE layoffs_staging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

SELECT DISTINCT country, TRIM(TRAILING "." from country)
FROM layoffs_staging2
order by 1
;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING "." from country)
WHERE country LIKE "United States%";

SELECT `date`,
str_to_date(`date`, "%m/%d/%Y")
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, "%m/%d/%Y")
;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Null Values or Blank values

UPDATE layoffs_staging2
SET industry = null
WHERE industry = "";

SELECT *
FROM layoffs_staging2
WHERE industry is NULL or industry = "";

SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb";

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS null
AND t2.industry IS NOT NULL
;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS null
AND t2.industry IS NOT NULL
;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL
;

DELETE
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL
;

-- 4. Remove Any Unnecesary Columns

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;






