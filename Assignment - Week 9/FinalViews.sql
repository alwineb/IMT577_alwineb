/*
1. Give an overall assessment of stores number 5 and 8’s sales. 
How are they performing compared to target? Will they meet their 2014 target?
Should either store be closed? Why or why not?
What should be done in the next year to maximize store profits?
*/


-- To give an overall assessment of the stores, I will be looking at the stores 5 & 8 and their respective sales on a monthly basis.
-- The sales will be compared against their target values for the month, both of which are aggregated at the month level.
-- These values will help me see how the stores are performing against their targets and if there's any seasonanilty observed
-- The trend of 2013 can then be extrapolated to see if the 2014 target would be met for the last two months

CREATE OR REPLACE SECURE VIEW View_TargetVsSales_Month_Year_Wise_AllStates
AS
    WITH temp1 AS 
      (SELECT 
          ds.StoreNumber, 
          dd.YEAR, 
          dd.MONTH_NAME,
          dd.MONTH_NUM_IN_YEAR,  
          SUM(fsa.SaleAmount) AS TotalSales 
      FROM View_Fact_SalesActual fsa 
      JOIN View_Dim_Date dd 
          ON fsa.DimSaleDateID = dd.DATE_PKEY
      JOIN View_Dim_Store ds 
          ON fsa.DimStoreID = ds.DimStoreID
      JOIN View_Fact_SrcSalesTarget fsst 
          ON fsst.DimStoreID = ds.DimStoreID 
          AND fsst.DimTargetDateID = dd.DATE_PKEY
      WHERE fsa.DimStoreID in 
          (SELECT ds.DimStoreID FROM View_Dim_store ds WHERE ds.StoreNumber <> -1)
      GROUP BY 
         ds.StoreNumber, 
         dd.YEAR, 
         dd.MONTH_NAME,
         dd.MONTH_NUM_IN_YEAR),
    temp2 AS 
      (SELECT 
         ds.StoreNumber, 
         dd.YEAR, 
         dd.MONTH_NAME,
         dd.MONTH_NUM_IN_YEAR,   
         SUM(fsst.SalesTargetAmount) AS Target
      FROM View_Fact_SrcSalesTarget fsst 
      JOIN View_Dim_Date dd 
            ON fsst.DimTargetDateID = dd.DATE_PKEY
      JOIN View_Dim_Store ds 
            ON fsst.DimStoreID = ds.DimStoreID
      WHERE fsst.DimStoreID in 
            (SELECT ds.DimStoreID FROM View_Dim_store ds WHERE ds.StoreNumber<> -1)
      GROUP BY 
         ds.StoreNumber, 
         dd.YEAR, 
         dd.MONTH_NAME,
         dd.MONTH_NUM_IN_YEAR)
   
   SELECT 
       temp1.StoreNumber, 
       temp1.YEAR, 
       temp1.MONTH_NAME,
       temp1.MONTH_NUM_IN_YEAR,
       temp1.TOTALSALES, 
       temp2.TARGET 
   FROM temp1 
   JOIN temp2 
      ON temp1.StoreNumber = temp2.StoreNumber 
      AND temp1.YEAR = temp2.YEAR 
      AND temp1.MONTH_NAME = temp2.MONTH_NAME
   ORDER BY 
       temp1.StoreNumber, 
       temp1.YEAR,
       temp1.MONTH_NUM_IN_YEAR;
       
SELECT * FROM View_TargetVsSales_Month_Year_Wise_AllStates


________________________________________________________________


CREATE OR REPLACE SECURE VIEW View_ProfitsByStoreProduct_Month_Year_Wise 
AS 
  SELECT 
    dd.YEAR,
    ds.StoreNumber, 
    dd.MONTH_NUM_IN_YEAR,
    dd.MONTH_NAME,
    dp.PRODUCTNAME,
    dp.PRODUCTTYPE,
    dp.PRODUCTCATEGORY,
    SUM(fsa.SaleTotalProfit) AS TotalProfit
  FROM View_Fact_SalesActual fsa 
  JOIN View_Dim_Date dd 
    ON fsa.DimSaleDateID = dd.DATE_PKEY
  JOIN View_Dim_Store ds 
    ON fsa.DimStoreID = ds.DimStoreID
  JOIN VIEW_DIM_PRODUCT dp
    ON fsa.DIMPRODUCTID = dp.DIMPRODUCTID
  WHERE fsa.DimStoreID in 
    (SELECT ds.DimStoreID FROM View_Dim_store ds WHERE ds.StoreNumber<> -1)
  GROUP BY 
    ds.StoreNumber, 
    dd.YEAR,
    dd.MONTH_NAME,
    dd.MONTH_NUM_IN_YEAR,
    dp.PRODUCTCATEGORY,
    dp.PRODUCTTYPE,
    dp.PRODUCTNAME 
  ORDER BY 
    dd.YEAR,
    ds.STORENUMBER,
    dd.MONTH_NUM_IN_YEAR;




------------------------------------

CREATE OR REPLACE SECURE VIEW VIEW_PRODUCT_PERFORMANCE
AS
SELECT DP.SOURCEPRODUCTID AS PRODUCTID,DP.PRODUCTNAME AS PRODUCTNAME,DP.PRODUCTTYPE AS PRODUCTTYPE,DP.PRODUCTCATEGORY AS PRODUCTCATEGORY
,A.DIMSALEdateid,VDD.DAY_NAME,VDD.WEEK_NUM_IN_YEAR,VDD.MONTH_NAME, VDD.YEAR,A.ACTUAL_PROD_SALE,A.DIMSTOREID, 
ROUND(VPFS.PRODUCTTARGETSALESQUANTITY,0) AS PRODUCT_SALE_QTY_TARGET
FROM (SELECT DIMPRODUCTID,DIMSTOREID,DIMSALEdateid,ROUND(SUM(SALEQUANTITY),0) as ACTUAL_PROD_SALE FROM VIEW_FACT_SALESACTUAL WHERE DIMSTOREID IN (4,6)
GROUP BY 1,2,3) AS A
INNER JOIN 
VIEW_FACT_PRODUCTSALESTARGET VPFS 
ON VPFS.DIMPRODUCTID = A.DIMPRODUCTID AND A.DIMSALEDATEID = VPFS.DIMTARGETDATEID
INNER JOIN DIM_PRODUCT DP
ON DP.DIMPRODUCTID=A.DIMPRODUCTID
INNER JOIN 
VIEW_DIM_DATE AS VDD
ON VDD.DATE_PKEY = A.DIMSALEdateid;



-------------------------------------------------------

/*
2. Recommend separate 2013 and 2014 bonus amounts for each store if the total bonus pool for 2013 is $500,000 and 
the total bonus pool for 2014 is $400,000. Base your recommendation on how well the stores are selling Product Types
of Men’s Casual and Women’s Casual.
*/


--Answer

/*
While there is no absolutely fair method of distributing the bonus, some of the ways it could be done include
    1. Providing a part-bonus to all stores and part based on performance to top stores
    2. Providing a bonus to each store based on yearly sales revenue
    3. Providing a bonus to each store based on yearly profits
    4. Providing a bonus to each store based on yearly items sold
    
I created a sub-query with values of yearly sales, profits, and items sold. Post this, while looking at the data, I assumed that those stores
that sell more number of items would require more employees at any given point in time, thus amounting to larger bonus requirement. The caveat here
is that the bonus amounts would be allotted for each store irrespective of whether the stores sell luxury items or normal items. However,
since we are looking at men's and women's casuals only, I'm assuming that the items do not have a large variance in their selling prices/profits, and 
I decided the criteria as number of items sold. Now, while distributing the bonus among employees, each store could take a look at the 
revenue/profits/items due to each salesperson and distribute the bonus accordingly.
*/ 

select * from View_BonusAllocations
limit 5

CREATE SECURE VIEW View_BonusAllocations 
AS 
  WITH data_collector AS 
      (
      SELECT 
         ds.StoreNumber, 
         dd.YEAR, 
         SUM(fsa.SaleTotalProfit) AS TotalProfit, 
         SUM(fsa.SaleAmount) AS TotalSales, 
         SUM(fsa.SaleQuantity) AS TotalSalesQuantity
      FROM 
         View_Fact_SalesActual fsa 
      JOIN View_Dim_Date dd 
        ON fsa.DimSaleDateID = dd.DATE_PKEY
      JOIN View_Dim_Store ds 
        ON fsa.DimStoreID = ds.DimStoreID
      JOIN View_Dim_Product dp 
        ON fsa.DimProductID = dp.DimProductID
      WHERE fsa.DimStoreID in 
        (
          SELECT ds.DimStoreID 
          FROM View_Dim_store ds 
          WHERE ds.StoreNumber <> -1 -- We want data for actual stores only
        ) 
         AND dp.ProductType 
            in ('Women\'s Casual', 'Men\'s Casual') -- Filtering for the required product types
      GROUP BY 
        ds.StoreNumber, 
        dd.YEAR 
      )
      
SELECT 
    data_collector.YEAR, 
    data_collector.StoreNumber, 
    (
      CASE 
        when data_collector.YEAR = 2013 then 
             500000 * -- Total Bonus Amount
            (
              data_collector.TotalSalesQuantity / -- Total Quantity for a store
             (
               -- Total Quantity across all stores
               SELECT 
                SUM(data_collector.TotalSalesQuantity) 
               FROM data_collector
               WHERE data_collector.YEAR = 2013 
                AND data_collector.StoreNumber <> -1-- We want data for actual stores only
             )
            )
        when data_collector.YEAR = 2014 then 
             400000 * -- Total Bonus Amount
            (
              data_collector.TotalSalesQuantity / -- Total Quantity for a store
             (
               -- Total Quantity across all stores
               SELECT 
                SUM(data_collector.TotalSalesQuantity) 
               FROM data_collector
               WHERE data_collector.YEAR = 2013 
                AND data_collector.StoreNumber <> -1-- We want data for actual stores only
             )
            )
      END
    )
    AS QuantityBonusAllotted, 
    
    (
      CASE 
        when data_collector.YEAR = 2013 then 
             500000 * -- Total Bonus Amount
            (
              data_collector.TotalSales / -- Total Sales for a store
             (
               -- Total Quantity across all stores
               SELECT 
                SUM(data_collector.TotalSales) 
               FROM data_collector
               WHERE data_collector.YEAR = 2013 
                AND data_collector.StoreNumber <> -1-- We want data for actual stores only
             )
            )
        when data_collector.YEAR = 2014 then 
             400000 * -- Total Bonus Amount
            (
              data_collector.TotalSales / -- Total Quantity for a store
             (
               -- Total Quantity across all stores
               SELECT 
                SUM(data_collector.TotalSales) 
               FROM data_collector
               WHERE data_collector.YEAR = 2013 
                AND data_collector.StoreNumber <> -1-- We want data for actual stores only
             )
            )
      END
    )
    AS SalesBonusAllotted,
    
    (
      CASE 
        when data_collector.YEAR = 2013 then 
             500000 * -- Total Bonus Amount
            (
              data_collector.TotalProfit / -- Total Sales for a store
             (
               -- Total Quantity across all stores
               SELECT 
                SUM(data_collector.TotalProfit) 
               FROM data_collector
               WHERE data_collector.YEAR = 2013 
                AND data_collector.StoreNumber <> -1-- We want data for actual stores only
             )
            )
        when data_collector.YEAR = 2014 then 
             400000 * -- Total Bonus Amount
            (
              data_collector.TotalProfit / -- Total Quantity for a store
             (
               -- Total Quantity across all stores
               SELECT 
                SUM(data_collector.TotalProfit) 
               FROM data_collector
               WHERE data_collector.YEAR = 2013 
                AND data_collector.StoreNumber <> -1-- We want data for actual stores only
             )
            )
      END
    )
    AS ProfitBonusAllotted

    FROM data_collector
    ORDER BY 
        data_collector.YEAR, 
        data_collector.StoreNumber; 
        
        
        
        
/*
3. Assess product sales by day of the week at stores 5 and 8. What can we learn about sales trends?
*/


/* 
    Since the product-level is not mentioned, I have created a query that allows aggregation at the product cateogory, product type and product name level. 
    The data created can be further filtered or grouped for a specific analysis of product category, type, or product itself. These value can be looked
    at for day-wise trends at various levels.

*/

select * from View_ProductSales_Day_Wise_Storewise
--limit 5

-- STOREID 1 == STORE NUMBER 5
-- STOREID 5 == STORE NUMBER 8

CREATE SECURE VIEW View_ProductSales_Day_Wise_Storewise
AS
  SELECT 
    dd.DAY_NAME, 
    dp.ProductCategory, 
    dp.ProductType, 
    dp.ProductName,
    fsa.DimStoreID,
    SUM(fsa.SaleTotalProfit) AS TotalProfit, 
    SUM(fsa.SaleAmount) AS TotalSales, 
    SUM(fsa.SaleQuantity) AS TotalQuantity
    
  FROM View_Fact_SalesActual fsa 
  JOIN View_Dim_Date dd 
    ON fsa.DimSaleDateID = dd.DATE_PKEY
  JOIN View_Dim_Product dp 
    ON fsa.DimProductID = dp.DimProductID
  WHERE fsa.DimStoreID IN 
    (
       SELECT 
          ds.DimStoreID--,
          --ds.StoreNumber
       FROM View_Dim_store ds 
       WHERE 
          ds.StoreNumber = 5 
          OR ds.StoreNumber = 8
    )
  GROUP BY
    fsa.DimStoreID,
    dd.DAY_NAME, 
    dp.ProductCategory, 
    dp.ProductType, 
    dp.ProductName
  ORDER BY dd.DAY_NAME;
  



/*
4. Compare the performance of all stores located in states that have more than one store to all stores that are the only store
in the state. What can we learn about having more than one store in a state?
*/

/*
    For this query, since the performance-level is not mentioned, I have created a query that allows aggregation at the profit, sales, and sale quantity levels.
    The states have been categorized as 'one-stored states' and 'More than one-store states'. We see that the one-stored states in our data perform better in every case
*/


CREATE OR REPLACE SECURE VIEW View_SalesDetailByStateCityProduct 
AS
SELECT VDS.STORENUMBER,VDL.DIMLOCATIONID,VDD.YEAR, VDL.CITY, VDL.State_Province, dp.ProductCategory, 
        dp.ProductType, 
        dp.ProductName,SUM(VFSA.SALEAMOUNT) "TOTAL SALES",
SUM(VFSA.SALETOTALPROFIT) "TOTAL PROFIT", SUM(VFSA.SALEQUANTITY) "TOTAL QUANTITY"   FROM VIEW_DIM_LOCATION VDL
INNER JOIN VIEW_FACT_SALESACTUAL VFSA
ON VDL.DIMLOCATIONID = VFSA.DIMLOCATIONID
INNER JOIN VIEW_DIM_STORE VDS
ON VDS.DIMSTOREID = VFSA.DIMSTOREID
INNER JOIN VIEW_DIM_DATE VDD
ON VDD.DATE_PKEY = VFSA.DIMSALEDATEID
INNER JOIN View_Dim_Product dp 
    ON vfsa.DimProductID = dp.DimProductID
GROUP BY (1,2,3,4,5, 6, 7,8 )
order by 5;

select * from View_SalesDetailByStateCityProduct
group by 5
    