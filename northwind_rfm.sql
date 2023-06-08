CREATE DATABASE northwind 

-- Step 1: Calculate R-F-M for each customer
WITH fact_table AS(
    SELECT ord.orderID
        , ord.customerID
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
) 
SELECT COUNT(*)
FROM fact_table 

SELECT COUNT(*)
FROM order_details -- 2155 records

SELECT *
FROM [dbo].[customers]