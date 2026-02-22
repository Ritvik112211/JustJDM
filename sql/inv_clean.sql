
--  Author: Ritvik Awasthi
--  Description:   This script cleans and standardizes a raw product inventory table. 
--                  Fills missing categories based on Product_Name keywords
--                  Normalizes Year_Compatibility into Start_Year / End_Year
--                  Cleans text, trims whitespace, and converts dates
--                  Converts Discontinued to 'True'/'False'
--                  Adds optional category image URLs


-- 1) Start fresh
IF OBJECT_ID('dbo.inv_clean', 'U') IS NOT NULL
  DROP TABLE dbo.inv_clean;
GO

-- 2) Create the cleaned table
CREATE TABLE dbo.inv_clean (
    Product_ID           varchar(50),
    Product_Name         varchar(255),
    Brand                varchar(100),
    Category             varchar(100),
    Car_Model            varchar(255),
    Year_Compatibility   varchar(50),
    Start_Year           int NULL,
    End_Year             int NULL,
    Cost_Price_USD       decimal(18,2),
    Sales_Price_USD      decimal(18,2),
    Stock_Level          int,
    Country_of_Origin    varchar(100),
    Supplier_Code        varchar(100),
    Warranty_Months      int,
    Weight_kg            decimal(18,2),
    Discontinued         varchar(5),
    Date_Added           date NULL,
    Last_Updated         date NULL,
    Performance_Tier     varchar(50)
);
GO

-- 3) Insert cleaned data
INSERT INTO dbo.inv_clean (
    Product_ID, Product_Name, Brand, Category, Car_Model, Year_Compatibility,
    Start_Year, End_Year, Cost_Price_USD, Sales_Price_USD, Stock_Level,
    Country_of_Origin, Supplier_Code, Warranty_Months, Weight_kg,
    Discontinued, Date_Added, Last_Updated, Performance_Tier
)
SELECT
    LTRIM(RTRIM(Product_ID))        AS Product_ID,
    LTRIM(RTRIM(Product_Name))      AS Product_Name,
    LTRIM(RTRIM(Brand))             AS Brand,
    CASE
        WHEN NULLIF(LTRIM(RTRIM(Category)), '') IS NOT NULL
            THEN LTRIM(RTRIM(Category))
        ELSE
            CASE
                WHEN LOWER(Product_Name) LIKE '%turbo%' OR LOWER(Product_Name) LIKE '%intercooler%'
                  OR LOWER(Product_Name) LIKE '%downpipe%' OR LOWER(Product_Name) LIKE '%exhaust%'
                  OR LOWER(Product_Name) LIKE '%cat-back%' OR LOWER(Product_Name) LIKE '%header%'
                  OR LOWER(Product_Name) LIKE '%muffler%' OR LOWER(Product_Name) LIKE '%intake%'
                  OR LOWER(Product_Name) LIKE '%air filter%' OR LOWER(Product_Name) LIKE '%cold air%'
                    THEN 'Intake & Exhaust'
                WHEN LOWER(Product_Name) LIKE '%clutch%' OR LOWER(Product_Name) LIKE '%flywheel%'
                  OR LOWER(Product_Name) LIKE '%gear%' OR LOWER(Product_Name) LIKE '%transmission%'
                  OR LOWER(Product_Name) LIKE '%drivetrain%' OR LOWER(Product_Name) LIKE '%lsd%'
                  OR LOWER(Product_Name) LIKE '%differential%'
                    THEN 'Transmission & Drivetrain'
                WHEN LOWER(Product_Name) LIKE '%suspension%' OR LOWER(Product_Name) LIKE '%coilover%'
                  OR LOWER(Product_Name) LIKE '%spring%' OR LOWER(Product_Name) LIKE '%damper%'
                  OR LOWER(Product_Name) LIKE '%shock%' OR LOWER(Product_Name) LIKE '%camber%'
                  OR LOWER(Product_Name) LIKE '%control arm%' OR LOWER(Product_Name) LIKE '%bushing%'
                    THEN 'Suspension & Handling'
                WHEN LOWER(Product_Name) LIKE '%brake%' OR LOWER(Product_Name) LIKE '%rotor%'
                  OR LOWER(Product_Name) LIKE '%caliper%' OR LOWER(Product_Name) LIKE '%pad%'
                  OR LOWER(Product_Name) LIKE '%line%'
                    THEN 'Brakes & Rotors'
                WHEN LOWER(Product_Name) LIKE '%wheel%' OR LOWER(Product_Name) LIKE '%rim%'
                  OR LOWER(Product_Name) LIKE '%lug%' OR LOWER(Product_Name) LIKE '%spacer%' OR LOWER(Product_Name) LIKE '%tire%'
                    THEN 'Wheels & Tires'
                WHEN LOWER(Product_Name) LIKE '%radiator%' OR LOWER(Product_Name) LIKE '%oil cooler%' OR LOWER(Product_Name) LIKE '%coolant%' OR LOWER(Product_Name) LIKE '%thermostat%'
                    THEN 'Cooling'
                WHEN LOWER(Product_Name) LIKE '%ecu%' OR LOWER(Product_Name) LIKE '%boost controller%' OR LOWER(Product_Name) LIKE '%gauge%' OR LOWER(Product_Name) LIKE '%wideband%' OR LOWER(Product_Name) LIKE '%sensor%' OR LOWER(Product_Name) LIKE '%electronic%'
                    THEN 'Electronics'
                WHEN LOWER(Product_Name) LIKE '%aero%' OR LOWER(Product_Name) LIKE '%diffuser%' OR LOWER(Product_Name) LIKE '%lip%' OR LOWER(Product_Name) LIKE '%spoiler%' OR LOWER(Product_Name) LIKE '%splitter%' OR LOWER(Product_Name) LIKE '%canard%' OR LOWER(Product_Name) LIKE '%body kit%' OR LOWER(Product_Name) LIKE '%fender%' OR LOWER(Product_Name) LIKE '%bumper%'
                    THEN 'Exterior & Aerodynamics'
                WHEN LOWER(Product_Name) LIKE '%fuel pump%' OR LOWER(Product_Name) LIKE '%injector%' OR LOWER(Product_Name) LIKE '%rail%' OR LOWER(Product_Name) LIKE '%regulator%'
                    THEN 'Fuel System'
                WHEN LOWER(Product_Name) LIKE '% filter%' OR LOWER(Product_Name) LIKE '%oil%' OR LOWER(Product_Name) LIKE '%spark plug%'
                    THEN 'Maintenance'
                ELSE 'Uncategorized'
            END
    END AS Category,
    LTRIM(RTRIM(Car_Model)) AS Car_Model,
    REPLACE(REPLACE(LTRIM(RTRIM(Year_Compatibility)), N'–', '-'), N'—', '-') AS Year_Compatibility,
    CASE
        WHEN LEN(REPLACE(REPLACE(LTRIM(RTRIM(Year_Compatibility)), N'–', '-'), N'—', '-')) >= 4
             AND ISNUMERIC(LEFT(REPLACE(REPLACE(LTRIM(RTRIM(Year_Compatibility)), N'–', '-'), N'—', '-'),4)) = 1
          THEN CAST(LEFT(REPLACE(REPLACE(LTRIM(RTRIM(Year_Compatibility)), N'–', '-'), N'—', '-'),4) AS int)
        ELSE NULL
    END AS Start_Year,
    CASE
        WHEN REPLACE(REPLACE(LTRIM(RTRIM(Year_Compatibility)), N'–', '-'), N'—', '-') LIKE '%-%'
          THEN TRY_CONVERT(int,
                    SUBSTRING(REPLACE(REPLACE(LTRIM(RTRIM(Year_Compatibility)), N'–', '-'), N'—', '-'),
                    CHARINDEX('-', REPLACE(REPLACE(LTRIM(RTRIM(Year_Compatibility)), N'–', '-'), N'—', '-')) + 1,
                    4))
        ELSE NULL
    END AS End_Year,
    Cost_Price_USD,
    Sales_Price_USD,
    Stock_Level,
    LTRIM(RTRIM(Country_of_Origin)) AS Country_of_Origin,
    LTRIM(RTRIM(Supplier_Code)) AS Supplier_Code,
    Warranty_Months,
    Weight_kg,
    CASE LOWER(LTRIM(RTRIM(CAST(Discontinued AS varchar(20)))))
        WHEN 'true' THEN 'True'
        WHEN 'false' THEN 'False'
        WHEN 'yes' THEN 'True'
        WHEN 'no' THEN 'False'
        WHEN '1' THEN 'True'
        WHEN '0' THEN 'False'
        ELSE 'False'
    END AS Discontinued,
    TRY_CONVERT(date, Date_Added)   AS Date_Added,
    TRY_CONVERT(date, Last_Updated) AS Last_Updated,
    LTRIM(RTRIM(Performance_Tier))  AS Performance_Tier
FROM dbo.inv_raw;
GO

-- 4) Adds Image URLs by Category
IF COL_LENGTH('dbo.inv_clean', 'Image_URL') IS NULL
BEGIN
    ALTER TABLE dbo.inv_clean ADD Image_URL VARCHAR(255) NULL;
END;
GO

UPDATE c
SET Image_URL =
    CASE
        WHEN Category = 'Suspension & Handling'       THEN 'https://ibb.co/hFbK16vC'
        WHEN Category = 'Transmission & Drivetrain'   THEN 'https://ibb.co/fd5Cdndk'
        WHEN Category = 'Exterior & Aerodynamics'     THEN 'https://ibb.co/FLNZPFJN'
        WHEN Category = 'Brakes & Rotors'             THEN 'https://ibb.co/tMBk3rRD'
        WHEN Category = 'Engine & Performance'        THEN 'https://ibb.co/gMGfYCz3'
        WHEN Category IN ('Exhaust & Intake','Intake & Exhaust')
                                                      THEN 'https://ibb.co/20sG87h5'
        ELSE Image_URL
    END
FROM dbo.inv_clean AS c;
GO

-- 5) Quick Data Quality Checks
SELECT TOP (10) * FROM dbo.inv_clean;

SELECT Product_ID, COUNT(*) AS dupes
FROM dbo.inv_clean
GROUP BY Product_ID
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS Sales_Below_Cost
FROM dbo.inv_clean
WHERE Sales_Price_USD < Cost_Price_USD;
GO
