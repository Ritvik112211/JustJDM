
-- ===============================================================
-- Project: JDM Sales • Final Dataset Builder (2021–2024)
-- File:   JDM_FinalDataset_2021_2024.sql
-- Author: Ritvik Awasthi
-- About:  Produces a final, analysis-ready dataset by joining:
--           1) Sales (orders 2021–2024)
--           2) Discounts (latest per month & customer category)
--           3) Inventory (product catalog)
--         Computes Applied_Discount, Discount_Band, revenue, total_cost,
--         and Discount_revenue.
-- ===============================================================

/* =====================[ Parameters ]===================== */
DECLARE @LowMax decimal(9,4) = 0.05;  -- Low band:   up to 5%
DECLARE @MedMax decimal(9,4) = 0.15;  -- Medium band: up to 15%

/* =============[ 1) Sales filtered to 2021–2024 ]============= */
WITH Sales_Base AS (
    SELECT
        s.*,
        -- Normalize order date to 'YYYY-MM' for monthly discount matching
        CONVERT(varchar(7), TRY_CONVERT(date, s.Order_Date, 120), 120) AS Effective_Month,
        -- Align naming with discounts table
        s.Customer_Type AS Customer_Category
    FROM dbo.SalesLog_JDM_Cleaned_v1 AS s
    WHERE YEAR(TRY_CONVERT(date, s.Order_Date, 120)) IN (2021, 2022, 2023, 2024)
),

/* ===[ 2) Latest discount per (Effective_Month, Customer_Category) ]=== */
Discount_Dedup AS (
    SELECT d.*
    FROM (
        SELECT
            d.*,
            ROW_NUMBER() OVER (
                PARTITION BY d.Effective_Month, d.Customer_Category
                ORDER BY TRY_CONVERT(datetime, d.Date_Approved, 120) DESC
            ) AS rn
        FROM dbo.JDM_Discount_Log_Clean AS d
    ) d
    WHERE d.rn = 1
),

/* ===============[ 3) Sales + Discount join ]=============== */
Joined_SD AS (
    SELECT
        sb.*,
        dd.Min_Discount,
        dd.Max_Discount,
        dd.Standard_Discount,
        dd.Promo_Discount,
        dd.Date_Approved
    FROM Sales_Base sb
    LEFT JOIN Discount_Dedup dd
      ON sb.Effective_Month   = dd.Effective_Month
     AND sb.Customer_Category = dd.Customer_Category
),

/* ======[ 4) Normalize % values (10 => 0.10) ]====== */
Normalized AS (
    SELECT
        j.*,
        CASE WHEN TRY_CONVERT(decimal(9,4), j.Min_Discount)      > 1 THEN TRY_CONVERT(decimal(9,4), j.Min_Discount)      / 100.0 ELSE TRY_CONVERT(decimal(9,4), j.Min_Discount)      END AS Min_n,
        CASE WHEN TRY_CONVERT(decimal(9,4), j.Max_Discount)      > 1 THEN TRY_CONVERT(decimal(9,4), j.Max_Discount)      / 100.0 ELSE TRY_CONVERT(decimal(9,4), j.Max_Discount)      END AS Max_n,
        CASE WHEN TRY_CONVERT(decimal(9,4), j.Standard_Discount) > 1 THEN TRY_CONVERT(decimal(9,4), j.Standard_Discount) / 100.0 ELSE TRY_CONVERT(decimal(9,4), j.Standard_Discount) END AS Std_n,
        CASE WHEN TRY_CONVERT(decimal(9,4), j.Promo_Discount)    > 1 THEN TRY_CONVERT(decimal(9,4), j.Promo_Discount)    / 100.0 ELSE TRY_CONVERT(decimal(9,4), j.Promo_Discount)    END AS Promo_n
    FROM Joined_SD j
),

/* =========[ 5) Applied_Discount & Discount_Band ]========= */
Applied AS (
    SELECT
        n.*,
        CASE
            WHEN n.Promo_n IS NOT NULL THEN n.Promo_n
            WHEN n.Std_n IS NOT NULL AND n.Min_n IS NOT NULL AND n.Max_n IS NOT NULL THEN
                CASE
                    WHEN n.Std_n < n.Min_n THEN n.Min_n
                    WHEN n.Std_n > n.Max_n THEN n.Max_n
                    ELSE n.Std_n
                END
            ELSE n.Std_n
        END AS Applied_Discount
    FROM Normalized n
),
Banding AS (
    SELECT
        a.*,
        CASE
            WHEN a.Applied_Discount IS NULL OR a.Applied_Discount = 0                 THEN 'None'
            WHEN a.Applied_Discount > 0        AND a.Applied_Discount <= @LowMax      THEN 'Low'
            WHEN a.Applied_Discount > @LowMax  AND a.Applied_Discount <= @MedMax      THEN 'Medium'
            WHEN a.Applied_Discount > @MedMax                                           THEN 'High'
            ELSE 'None'
        END AS Discount_Band
    FROM Applied a
),

/* =====[ 6) JDMSALES (Order-based) with product enrichment ]===== */
JDMSALES AS (
    SELECT
        -- Identity
        B.Order_ID,

        -- Product enrichment (via Product_ID)
        B.Product_ID,
        I.Product_Name,
        I.Brand,
        I.Category,
        I.Sales_Price_USD AS Sale_Price,
        I.Cost_Price_USD  AS Cost_Price,
        I.Image_URL,

        -- Sales facts
        B.Order_Date      AS [Date],
        B.Customer_Type,
        B.Discount_Band,
        B.Country,
        B.Units_Sold,

        -- Financials
        (I.Sales_Price_USD * B.Units_Sold) AS revenue,
        (I.Cost_Price_USD  * B.Units_Sold) AS total_cost,

        -- Time features
        DATENAME(MONTH, TRY_CONVERT(date, B.Order_Date, 120)) AS [month],
        YEAR(TRY_CONVERT(date, B.Order_Date, 120))            AS [year],

        -- Discount for final computation
        B.Applied_Discount
    FROM Banding AS B
    LEFT JOIN dbo.Inv_JDM_Realistic_WITH_IMAGES AS I
      ON B.Product_ID = I.Product_ID
)

/* =====[ 7) Final dataset ]===== */
SELECT
    JS.*,
    (1 - ISNULL(JS.Applied_Discount, 0)) * JS.revenue AS Discount_revenue
FROM JDMSALES AS JS
ORDER BY JS.Date, JS.Order_ID;
