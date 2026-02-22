
-- ==============================================
-- CLEANING SCRIPT FOR JDM_Discount_Log_Dirty.csv
-- ==============================================

-- 1. Remove duplicates (requires temporary table or CTE)
DELETE FROM JDM_Discount_Log_Dirty
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM JDM_Discount_Log_Dirty
  GROUP BY Effective_Month, Customer_Category, Min_Discount, Max_Discount,
           Standard_Discount, Promo_Discount, Seasonal_Event, Date_Approved,
           Remarks, Discount_Percent
);

-- 2. Standardize date format
UPDATE JDM_Discount_Log_Dirty
SET Date_Approved = STRFTIME('%Y-%m-%d', Date_Approved);

-- 3. Clean Discount_Percent values
UPDATE JDM_Discount_Log_Dirty
SET Discount_Percent = 
    CASE
        WHEN Discount_Percent LIKE '%fifteen%' THEN 15
        WHEN Discount_Percent LIKE '%ten%' THEN 10
        WHEN Discount_Percent LIKE '%twenty%' THEN 20
        WHEN Discount_Percent LIKE '%hundred%' THEN 100
        WHEN Discount_Percent LIKE '%zero%' THEN 0
        WHEN Discount_Percent LIKE '%nine%' THEN 9
        WHEN Discount_Percent LIKE '%eight%' THEN 8
        WHEN Discount_Percent LIKE '%seven%' THEN 7
        WHEN Discount_Percent LIKE '%six%' THEN 6
        WHEN Discount_Percent LIKE '%five%' THEN 5
        WHEN Discount_Percent LIKE '%four%' THEN 4
        WHEN Discount_Percent LIKE '%three%' THEN 3
        WHEN Discount_Percent LIKE '%two%' THEN 2
        WHEN Discount_Percent LIKE '%one%' THEN 1
        WHEN Discount_Percent LIKE '%\%%' THEN REPLACE(Discount_Percent, '%', '')
        WHEN Discount_Percent LIKE '%,%' THEN REPLACE(Discount_Percent, ',', '.')
        WHEN TRY_CAST(Discount_Percent AS FLOAT) < 0 OR TRY_CAST(Discount_Percent AS FLOAT) > 100 THEN NULL
        ELSE TRY_CAST(Discount_Percent AS FLOAT)
    END;

-- 4. Trim text columns
UPDATE JDM_Discount_Log_Dirty
SET Customer_Category = TRIM(Customer_Category),
    Seasonal_Event = NULLIF(TRIM(Seasonal_Event), ''),
    Remarks = NULLIF(TRIM(Remarks), '');

-- 5. Replace missing Promo_Discount with NULL where zero or invalid
UPDATE JDM_Discount_Log_Dirty
SET Promo_Discount = NULL
WHERE Promo_Discount IS NULL OR Promo_Discount = 0;
