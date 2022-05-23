--===================================================
----Pass-through views of Dimension and Fact Tables
--==================================================

CREATE VIEW VIEW_DIM_CHANNEL
AS
SELECT  
        DIMCHANNELID, 
        SOURCECHANNELID, 
        SOURCECHANNELCATEGORYID, 
        CHANNELNAME, 
        CHANNELCATEGORY
FROM DIM_CHANNEL;

CREATE VIEW VIEW_DIM_CUSTOMER
AS
SELECT  
        DIMCUSTOMERID, 
        DIMLOCATIONID, 
        SOURCECUSTOMERID, 
        FULLNAME, 
        FIRSTNAME,
        LASTNAME,
        GENDER,
        EMAILADDRESS,
        PHONENUMBER
FROM DIM_CUSTOMER;

CREATE VIEW VIEW_DIM_DATE
AS
SELECT 
        DATE_PKEY,
		DATE,
        FULL_DATE_DESC,
		DAY_NUM_IN_WEEK,
		DAY_NUM_IN_MONTH,
		DAY_NUM_IN_YEAR,
		DAY_NAME,
		DAY_ABBREV,
		WEEKDAY_IND,
		US_HOLIDAY_IND,
        _HOLIDAY_IND,
		MONTH_END_IND,
		WEEK_BEGIN_DATE_NKEY,
		WEEK_BEGIN_DATE,
		WEEK_END_DATE_NKEY,
		WEEK_END_DATE,
		WEEK_NUM_IN_YEAR,
		MONTH_NAME,
		MONTH_ABBREV,
		MONTH_NUM_IN_YEAR,
		YEARMONTH,
		QUARTER,
		YEARQUARTER,
		YEAR,
		FISCAL_WEEK_NUM,
		FISCAL_MONTH_NUM,
		FISCAL_YEARMONTH,
		FISCAL_QUARTER,
		FISCAL_YEARQUARTER,
		FISCAL_HALFYEAR,
		FISCAL_YEAR,
		SQL_TIMESTAMP,
		CURRENT_ROW_IND,
		EFFECTIVE_DATE,
		EXPIRATION_DATE
FROM DIM_DATE;


CREATE VIEW VIEW_DIM_LOCATION
AS
SELECT 
        DIMLOCATIONID,
        SOURCELOCATIONID, 
        POSTALCODE, 
        ADDRESS, 
        CITY, 
        STATE_PROVINCE, 
        COUNTRY
FROM DIM_LOCATION


CREATE VIEW VIEW_DIM_PRODUCT
AS
SELECT 
        DIMPRODUCTID,
        SOURCEPRODUCTID, 
        SOURCEPRODUCTTYPEID, 
        SOURCEPRODUCTCATEGORYID, 
        PRODUCTNAME, 
        PRODUCTTYPE, 
        PRODUCTCATEGORY,
        PRODUCTRETAILPRICE,
        PRODUCTWHOLESALEPRICE,
        PRODUCTCOST,
        PRODUCTRETAILPROFIT,
        PRODUCTWHOLESALEUNITPROFIT,
        PRODUCTPROFITMARGINUNITPERCENT
FROM DIM_PRODUCT

SELECT * FROM VIEW_DIM_PRODUCT
SELECT * FROM DIM_PRODUCT


CREATE VIEW VIEW_DIM_RESELLER
AS
SELECT 
        DIMRESELLERID,
        DIMLOCATIONID, 
        SOURCERESELLERID, 
        RESELLERNAME, 
        CONTACTNAME, 
        PHONENUMBER, 
        EMAIL
FROM DIM_RESELLER



CREATE VIEW View_Dim_Store
    AS
    SELECT 
        DimStoreID,
        DimLocationID, 
        SourceStoreID, 
        StoreNumber, 
        StoreManager
    FROM Dim_Store
    
SELECT * FROM View_Dim_Store
SELECT * FROM Dim_Store

CREATE VIEW view_fact_salesactual
AS
SELECT
  DimProductID,
  DimStoreID,
  DimResellerID,
  DimCustomerID,
  DimChannelID,
  DimSaleDateID,
  DimLocationID,
  SourceSalesHeaderID,
  SourceSalesDetailID,
  SaleAmount,
  SaleQuantity,
  SaleUnitPrice,
  SaleExtendedCost,
  SaleTotalProfit
FROM Fact_SalesActual;


CREATE VIEW view_fact_SRCSalesTarget
AS
SELECT
  DimStoreID,
  DimResellerID,
  DimChannelID,
  DimTargetDateID,
  SalestargetAmount
FROM Fact_SRCSalestarget;


CREATE VIEW view_fact_ProductSalesTarget
AS
SELECT
    DimProductID,
    DimTargetDateID,
    PRODUCTTARGETSALESQUANTITY
FROM fact_productsalestarget;


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

CREATE VIEW View_TargetVsSales_Month_Year_Wise 
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
          (SELECT ds.DimStoreID FROM View_Dim_store ds WHERE ds.StoreNumber = 5 or ds.StoreNumber = 8)
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
            (SELECT ds.DimStoreID FROM View_Dim_store ds WHERE ds.StoreNumber = 5 or ds.StoreNumber = 8)
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


select * from View_TargetVsSales_Month_Year_Wise


-- To look at whether any store needs to be closed, I will be assessing their profits aggregated over all products at the month-level
-- The month-level aggregation would help me consider if any months have better profits observed across both stores to focus on extra offers during 
-- the less profitable months so as to maximize profits

CREATE VIEW View_ProfitsByStore_Month_Year_Wise 
AS 
  SELECT 
    dd.YEAR,
    ds.StoreNumber, 
    dd.MONTH_NUM_IN_YEAR,
    dd.MONTH_NAME,
    SUM(fsa.SaleTotalProfit) AS TotalProfit
  FROM View_Fact_SalesActual fsa 
  JOIN View_Dim_Date dd 
    ON fsa.DimSaleDateID = dd.DATE_PKEY
  JOIN View_Dim_Store ds 
    ON fsa.DimStoreID = ds.DimStoreID
  WHERE fsa.DimStoreID in 
    (SELECT ds.DimStoreID FROM View_Dim_store ds WHERE ds.StoreNumber = 5 or ds.StoreNumber = 8)
  GROUP BY 
    ds.StoreNumber, 
    dd.YEAR,
    dd.MONTH_NAME,
    dd.MONTH_NUM_IN_YEAR
  ORDER BY 
    dd.YEAR,
    ds.STORENUMBER,
    dd.MONTH_NUM_IN_YEAR;


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

CREATE OR REPLACE VIEW View_BonusAmounts 
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
    AS BonusAllotted 
    FROM data_collector
    ORDER BY 
        data_collector.YEAR, 
        data_collector.StoreNumber; 
    
    
select * from "IMT577_DW_ALWIN_ELDHOSE"."PUBLIC"."VIEW_BONUSAMOUNTS"



/*
3. Assess product sales by day of the week at stores 5 and 8. What can we learn about sales trends?
*/


/* 
    Since the product-level is not mentioned, I have created a query that allows aggregation at the product cateogory, product type and product name level. 
    The data created can be further filtered or grouped for a specific analysis of product category, type, or product itself. These value can be looked
    at for day-wise trends at various levels.

*/
CREATE VIEW View_ProductSales_Day_Wise
AS
  SELECT 
    dd.DAY_ABBREV, 
    dp.ProductCategory, 
    dp.ProductType, 
    dp.ProductName,
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
          ds.DimStoreID 
       FROM View_Dim_store ds 
       WHERE 
          ds.StoreNumber = 5 
          OR ds.StoreNumber = 8
    )
  GROUP BY 
    dd.DAY_ABBREV, 
    dp.ProductCategory, 
    dp.ProductType, 
    dp.ProductName
  ORDER BY dd.DAY_ABBREV


/*
4. Compare the performance of all stores located in states that have more than one store to all stores that are the only store
in the state. What can we learn about having more than one store in a state?
*/

/*
    For this query, since the performance-level is not mentioned, I have created a query that allows aggregation at the profit, sales, and sale quantity levels.
    The states have been categorized as 'one-stored states' and 'More than one-store states'. We see that the one-stored states in our data perform better in every case
*/


CREATE VIEW View_SalesByLocationCategory 
AS
WITH Check_StoreCount AS 
  (
    SELECT 
        dl.State_Province, 
        COUNT(*) AS StoreCount
    FROM View_Dim_Store ds 
    JOIN View_Dim_Location dl 
        ON ds.DimLocationID = dl.DimLocationID
  GROUP BY dl.State_Province
  )
SELECT 
        (
          CASE WHEN Check_StoreCount.STORECOUNT > 1 
            THEN 'More than one-store states'
          WHEN Check_StoreCount.STORECOUNT =1 
            then 'One-stored states'
          END
        ) AS LocationCategory,
        SUM(fsa.SaleTotalProfit) AS TotalProfit, 
        SUM(fsa.SaleAmount) AS TotalSales, 
        SUM(fsa.SaleQuantity) AS TotalSalesQuantity
FROM Check_StoreCount, 
    View_Fact_SalesActual fsa
GROUP BY 
    LocationCategory;