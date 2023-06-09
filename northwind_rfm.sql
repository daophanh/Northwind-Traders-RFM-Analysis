CREATE DATABASE northwind; 

-- Step 1: The first step in building an RFM model is to assign Recency, Frequency and Monetary values to each customer.

WITH fact_table AS (
    SELECT ord.orderID
        , ord.customerID
        , ord.orderDate
        , details.productID
        , details.unitPrice
        , details.quantity
        , details.discount
        , cus.companyName
        , cus.city
        , cus.country
    FROM [dbo].[orders] AS ord
    LEFT JOIN [dbo].[order_details] AS details
        ON ord.orderID = details.orderID
    LEFT JOIN [dbo].[customers] AS cus
        ON ord.customerID = cus.customerID
) -- Step 2: calculate Recency, Frequency, Monetary
, rfm_table AS ( 
SELECT customerID
    , DATEDIFF(day,MAX(orderDate),'2015-05-06') AS recency --The reference date is 2015-05-31. The difference between the reference date and maximum date in the dataframe for each customer(which is the recent visit) is Recency 
    , COUNT (DISTINCT orderID) AS frequency -- We can get the Frequency of the customer by summing up the number of orders.
    , ROUND(SUM(unitPrice * quantity * (1-discount) * 0.1),2) AS monetary -- Monetary can be calculated as the sum of the Amount of all orders by each customer.
FROM fact_table
GROUP BY customerID
) -- Step 3: Ranking r, f, m, values (from 0 to 1)
, rank_table AS (
SELECT *
    , PERCENT_RANK() OVER (ORDER BY recency ASC) AS r_rank
    , PERCENT_RANK() OVER (ORDER BY frequency DESC) AS f_rank
    , PERCENT_RANK() OVER (ORDER BY monetary DESC) AS m_rank  
FROM rfm_table
) -- Step 4: Categorise into 4 tiers 
, tier_table AS (
SELECT *
    , CASE  WHEN r_rank > 0.75 THEN 4
            WHEN r_rank > 0.6 THEN 3
            WHEN r_rank > 0.25 THEN 2
            ELSE 1 END AS r_tier
    , CASE  WHEN f_rank > 0.75 THEN 4
            WHEN f_rank > 0.5 THEN 3
            WHEN f_rank > 0.25 THEN 2
            ELSE 1 END AS f_tier
    , CASE  WHEN m_rank > 0.75 THEN 4
            WHEN m_rank > 0.5 THEN 3
            WHEN m_rank > 0.25 THEN 2
            ELSE 1 END AS m_tier
FROM rank_table
) -- Step 5: Concanate r_tier, f_tier, m_tier to get rfm_score of each customer
, score_table AS (
SELECT customerID
    , recency
    , frequency
    , monetary
    , r_rank
    , f_rank
    , m_rank
    , CONCAT (r_tier, f_tier, m_tier) AS rfm_score
FROM tier_table
) -- Step 6: Segment customers into 9 groups 
, segment_table AS ( 
SELECT *
    , CASE  WHEN rfm_score = 111 THEN 'Best Customers'
            WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customers'  -- R3: 1-2 month, R4: > 2month -> KH rời bỏ mà còn siêu tệ (F thấp, số lần mua hàng ít)
            WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers' -- F3: 5->7, F2: 8->11 -> KH cũng rời bỏ nhưng có valued (F = 5->7)
            WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost'  -- R2: 1 month, F1: 12->31
            WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers' -- R1: 1 week, F1: 12->31
            WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders' 
            WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' 
            WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating' -- ngủ đông (trc đó từng rất là tốt )
            WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' -- có tiềm năng, R: 1->3w, F:5->11
            ELSE 'Unknown'
            END AS segment_label
FROM score_table
) -- Step 7: Calculate number of customer in each segment and its percentage
SELECT segment_label
    , COUNT(customerID) AS number_customer
    , SUM(COUNT(customerID)) OVER () AS total_customer
    , FORMAT(COUNT(customerID)*1.0/SUM(COUNT(customerID)) OVER(),'p') AS pct 
FROM segment_table
GROUP BY segment_label
ORDER BY number_customer DESC;







-- Testing:
SELECT COUNT(*), COUNT(customerID), COUNT(DISTINCT customerID)
FROM orders -- 830 records, 830, 89 customers

SELECT MIN(orderDate), MAX(orderDate)
FROM [dbo].[orders]

-- Testing Recency, Frequency, Monetary
SELECT customerID
    , orderID
    , orderDate
FROM orders
WHERE customerID IN ('VINET', 'WOLZA', 'VINET')  -- 52 6, WOLZA 38 7, VINET 200 5

-- Testing Recency
WITH fact_table AS (
    SELECT ord.orderID
        , ord.customerID
        , ord.orderDate
        , details.productID
        , details.unitPrice
        , details.quantity
        , details.discount
        , cus.companyName
        , cus.city
        , cus.country
    FROM [dbo].[orders] AS ord
    LEFT JOIN [dbo].[order_details] AS details
        ON ord.orderID = details.orderID
    LEFT JOIN [dbo].[customers] AS cus
        ON ord.customerID = cus.customerID
) -- Step 2: calculate Recency, Frequency, Monetary
, rfm_table AS ( 
SELECT customerID
    , DATEDIFF(day,MAX(orderDate),'2015-05-06') AS recency --The reference date is 2015-05-31. The difference between the reference date and maximum date in the dataframe for each customer(which is the recent visit) is Recency 
FROM fact_table
GROUP BY customerID
)
, rank_table AS (
SELECT *
    , PERCENT_RANK() OVER (ORDER BY recency ASC) AS r_rank
FROM rfm_table
) -- Step 4: Categorise into 4 tiers 
-- , tier_table AS (
SELECT *
    , CASE  WHEN r_rank > 0.75 THEN 4
            WHEN r_rank > 0.6 THEN 3
            WHEN r_rank > 0.25 THEN 2
            ELSE 1 END AS r_tier
FROM rank_table;

-- Testing Frequency
WITH fact_table AS (
    SELECT ord.orderID
        , ord.customerID
        , ord.orderDate
        , details.productID
        , details.unitPrice
        , details.quantity
        , details.discount
        , cus.companyName
        , cus.city
        , cus.country
    FROM [dbo].[orders] AS ord
    LEFT JOIN [dbo].[order_details] AS details
        ON ord.orderID = details.orderID
    LEFT JOIN [dbo].[customers] AS cus
        ON ord.customerID = cus.customerID
) -- Step 2: calculate Recency, Frequency, Monetary
, rfm_table AS ( 
SELECT customerID
    , COUNT (DISTINCT orderID) AS frequency 
FROM fact_table
GROUP BY customerID
) -- Step 3: Ranking r, f, m, values (from 0 to 1)
, rank_table AS (
SELECT *
    , PERCENT_RANK() OVER (ORDER BY frequency DESC) AS f_rank
FROM rfm_table
) -- Step 4: Categorise into 4 tiers 
SELECT *
    , CASE  WHEN f_rank > 0.75 THEN 4
            WHEN f_rank > 0.5 THEN 3
            WHEN f_rank > 0.25 THEN 2
            ELSE 1 END AS f_tier
FROM rank_table;

-- Testing monetary
WITH fact_table AS (
    SELECT ord.orderID
        , ord.customerID
        , ord.orderDate
        , details.productID
        , details.unitPrice
        , details.quantity
        , details.discount
        , cus.companyName
        , cus.city
        , cus.country
    FROM [dbo].[orders] AS ord
    LEFT JOIN [dbo].[order_details] AS details
        ON ord.orderID = details.orderID
    LEFT JOIN [dbo].[customers] AS cus
        ON ord.customerID = cus.customerID
) -- Step 2: calculate Recency, Frequency, Monetary
, rfm_table AS ( 
SELECT customerID
    , ROUND(SUM(unitPrice * quantity * (1-discount) * 0.1),2) AS monetary -- Monetary can be calculated as the sum of the Amount of all orders by each customer.
FROM fact_table
GROUP BY customerID
) -- Step 3: Ranking r, f, m, values (from 0 to 1)
, rank_table AS (
SELECT *
    , PERCENT_RANK() OVER (ORDER BY monetary DESC) AS m_rank  
FROM rfm_table
) -- Step 4: Categorise into 4 tiers 
SELECT *
    , CASE  WHEN m_rank > 0.75 THEN 4
            WHEN m_rank > 0.5 THEN 3
            WHEN m_rank > 0.25 THEN 2
            ELSE 1 END AS m_tier
FROM rank_table