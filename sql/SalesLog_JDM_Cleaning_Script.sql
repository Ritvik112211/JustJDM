-- CLEANING SCRIPT FOR SalesLog_JDM_Dirty_for_SQL_REISSUE

-- 1. Convert date to ISO and null invalid ones
UPDATE SalesLog
SET Order_Date = TRY_CONVERT(date,
    CASE 
        WHEN Order_Date LIKE '%/%' THEN REPLACE(Order_Date, '/', '-')
        ELSE Order_Date 
    END, 111)
WHERE ISDATE(Order_Date) = 0;

-- 2. Standardize Country
UPDATE SalesLog
SET Country = CASE 
    WHEN Country IN ('U.S.A.', 'USA', 'United States of America') THEN 'United States'
    ELSE Country END;

-- 3. Fix Units_Sold text values
UPDATE SalesLog
SET Units_Sold = CASE 
    WHEN Units_Sold = 'One' THEN 1
    WHEN Units_Sold = 'Two' THEN 2
    ELSE TRY_CAST(Units_Sold AS int)
END;

-- 4. Remove currency symbols and convert to numeric
UPDATE SalesLog
SET Shipping_Cost_USD = TRY_CAST(REPLACE(Shipping_Cost_USD, '$', '') AS decimal(10,2));

-- 5. Standardize Payment Method typos
UPDATE SalesLog
SET Payment_Method = CASE 
    WHEN Payment_Method LIKE '%Pay Pall%' THEN 'PayPal'
    WHEN Payment_Method LIKE '%Credit%' THEN 'Credit Card'
    ELSE Payment_Method END;

-- 6. Normalize boolean/categorical columns
UPDATE SalesLog
SET Customs_Clearance = CASE WHEN Customs_Clearance IN ('Y','Yes','YES') THEN 'Yes' ELSE 'No' END,
    Invoice_Approved = CASE WHEN Invoice_Approved IN ('Y','Yes','YES') THEN 'Yes' ELSE 'No' END,
    Return_Status = CASE WHEN Return_Status LIKE '%Return%' THEN 'Returned' ELSE 'Not Returned' END;

-- 7. Fix Agent name formatting (capitalize first letter)
UPDATE SalesLog
SET Agent = CONCAT(UPPER(LEFT(Agent,1)), LOWER(SUBSTRING(Agent,2,LEN(Agent))));

-- 8. Fill NULL Review_Score with group mean
UPDATE S
SET Review_Score = C.AvgScore
FROM SalesLog S
JOIN (
    SELECT Customer_Type, AVG(TRY_CAST(Review_Score AS float)) AS AvgScore
    FROM SalesLog
    WHERE Review_Score IS NOT NULL
    GROUP BY Customer_Type
) C
ON S.Customer_Type = C.Customer_Type
WHERE S.Review_Score IS NULL;

-- 9. Cast columns to appropriate SQL data types
ALTER TABLE SalesLog
ALTER COLUMN Shipping_Cost_USD DECIMAL(10,2);
ALTER TABLE SalesLog
ALTER COLUMN Units_Sold INT;
ALTER TABLE SalesLog
ALTER COLUMN Review_Score FLOAT;
ALTER TABLE SalesLog
ALTER COLUMN Order_Date DATE;
