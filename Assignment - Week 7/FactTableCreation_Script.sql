/*****************************************
Course: IMT 577
Instructor: Sean Pettersen
Assignment: Module 7
Date: 5/9/2022
Notes: Create Fact Tables and load their Data

*****************************************/

--===================================================
-------------FACT_PRODUCTSALESTARGET
--==================================================

select * from Dim_Date

DROP TABLE FACT_PRODUCTSALESTARGET

CREATE OR REPLACE TABLE FACT_PRODUCTSALESTARGET
(
    DimProductID INTEGER CONSTRAINT FK_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID) --Foreign Key
  
    ,DimTargetDateID NUMBER(9) CONSTRAINT FK_DimTargetDateID FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY) --Foreign Key
  
    ,ProductTargetSalesQuantity FLOAT
  
);



select * from FACT_PRODUCTSALESTARGET


--LOADING PRODUCTSALESTARGET TABLE FROM STAGE AND DIMENSIONAL TABLES
INSERT INTO FACT_PRODUCTSALESTARGET
	(
		 DimProductID
		,DimTargetDateID
		,ProductTargetSalesQuantity
	)
	SELECT DISTINCT
		  Dim_Product.DimProductID
		 ,Dim_Date.DATE_PKEY
         ,ROUND(STAGE_TARGETDATAPRODUCT.SALESQUANTITYTARGET/365,2) AS ProductTargetSalesQuantity
	FROM Dim_Product
    
    INNER JOIN STAGE_TARGETDATAPRODUCT ON
    STAGE_TARGETDATAPRODUCT.PRODUCTID = Dim_Product.DimProductID
    
	INNER JOIN Dim_Date ON
	Dim_Date.Year = STAGE_TARGETDATAPRODUCT.Year
    


select count (*) from FACT_PRODUCTSALESTARGET --verification of count = 365*2*24products = 17520

select * from Dim_Date
select * from STAGE_TARGETDATAPRODUCT

--===================================================
-------------FACT_SRCSalesTarget
--==================================================


CREATE OR REPLACE TABLE FACT_SRCSalesTarget
(
    DimStoreID INTEGER CONSTRAINT FK_DimStoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID) --Foreign Key
  
    ,DimResellerID INTEGER CONSTRAINT FK_DimResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID) --Foreign Key
  
    ,DimChannelID INTEGER CONSTRAINT FK_DimChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelID) --Foreign Key
  
    ,DimTargetDateID NUMBER(9) CONSTRAINT FK_DimTargetDateID FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY) --Foreign Key
  
    ,SalesTargetAmount FLOAT
  
);

select * from FACT_SRCSalesTarget

--LOADING SRCSalesTarget TABLE FROM STAGE AND DIMENSIONAL TABLES
INSERT INTO FACT_SRCSalesTarget
	(
		 DimStoreID
        ,DimResellerID
        ,DimChannelID
		,DimTargetDateID
		,SalesTargetAmount
	)
      SELECT 
          NVL(Dim_Store.DimStoreID,-1) AS DimStoreID,
          NVL(Dim_Reseller.DimResellerID,-1) AS DimResellerID,
          Dim_Channel.DimChannelID,
          Dim_Date.DATE_PKEY,
          ROUND(SRC.TARGETSALESAMOUNT/365,2) AS SalesTargetAmount
      FROM STAGE_TARGETDATACHANNEL SRC

      LEFT JOIN Dim_Store ON
      Dim_Store.StoreNumber = 
        (
          CASE
            WHEN SRC.TargetName = 'Store Number 5' then 5
            WHEN SRC.TargetName = 'Store Number 8' then 8
            WHEN SRC.TargetName = 'Store Number 10' then 10
            WHEN SRC.TargetName = 'Store Number 21' then 21
            WHEN SRC.TargetName = 'Store Number 34' then 34
            WHEN SRC.TargetName = 'Store Number 39' then 39
          END
          )

      LEFT JOIN Dim_Reseller ON
      Dim_Reseller.ResellerName = 
        (
          CASE
            WHEN SRC.TargetName = 'Mississippi Distributors' then 'Mississipi Distributors' -- As missisippi spelling is different in both
            ELSE SRC.TargetName
          END
          )

      INNER JOIN Dim_Channel
      ON Dim_Channel.ChannelName = CASE WHEN SRC.ChannelName = 'Online' THEN 'On-line' ELSE SRC.ChannelName END

      LEFT JOIN Dim_Date ON
      Dim_Date.Year = SRC.Year
    
    
    
select COUNT (*) from FACT_SRCSalesTarget -- verification of Count = 365*2*11 = 8030

--===================================================
-------------FACT_SRCSalesActual
--==================================================


CREATE OR REPLACE TABLE FACT_SalesActual
(
  DimProductID INTEGER CONSTRAINT Fk_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID),  --Foreign Key
  DimStoreID INTEGER CONSTRAINT Fk_DimStoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID),  --Foreign Key
  DimResellerID INTEGER CONSTRAINT Fk_DimResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID),  --Foreign Key
  DimCustomerID INTEGER CONSTRAINT Fk_DimCustomerID FOREIGN KEY REFERENCES Dim_Customer(DimCustomerID),  --Foreign Key
  DimChannelID INTEGER CONSTRAINT Fk_DimChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelID),  --Foreign Key
  DimSaleDateID NUMBER(9) CONSTRAINT FK_DimSaleDateID FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY), --Foreign Key
  DimLocationID INT CONSTRAINT Fk_DimLocationID FOREIGN KEY REFERENCES Dim_Location(DimLocationID), --Foreign Key
  
  SourceSalesHeaderID INTEGER NOT NULL,
  SourceSalesDetailID INTEGER NOT NULL,
  
  SaleAmount NUMERIC(8,2),
  SaleQuantity INTEGER,
  SaleUnitPrice NUMERIC(8,2),
  SaleExtendedCost NUMERIC(8,2),
  SaleTotalProfit NUMERIC(8,2)
  
);



--LOADING SalesActual TABLE FROM STAGE AND DIMENSIONAL TABLES
INSERT INTO FACT_SalesActual
	(
		 DimProductID
        ,DimStoreID
        ,DimResellerID
		,DimCustomerID
		,DimChannelID
        ,DimSaleDateID
        ,DimLocationID
      
        ,SourceSalesHeaderID
        ,SourceSalesDetailID
      
        ,SaleAmount
        ,SaleQuantity
        ,SaleUnitPrice
		,SaleExtendedCost
		,SaleTotalProfit
	)
    
    
    SELECT
       Dim_Product.DimProductID,
       NVL(Dim_Store.DimStoreID,-1) AS DimStoreID,
       NVL(Dim_Reseller.DimResellerID,-1) AS DimResellerID,
       NVL(Dim_Customer.DimCustomerID, -1) AS DimCustomerID,
       Dim_Channel.DimChannelID,
       
       --CAST(REPLACE(REPLACE(CAST(SH.Date AS Date), '00', '20'), '-', '') AS NUMBER(9)) AS DimSaleDateID,
       Dim_Date.Date_PKey AS DimSaleDateID,
       COALESCE(Dim_Store.DimLocationID, Dim_Reseller.DimLocationID, Dim_Customer.DimLocationID, -1) AS DimLocationID,
       
       SH.SalesHeaderID,
       SD.SalesDetailID,
       
       SD.SalesAmount,
       SD.SalesQuantity,
       CASE WHEN Dim_Reseller.DIMRESELLERID IS NOT NULL THEN Dim_Product.PRODUCTWHOLESALEPRICE ELSE Dim_Product.PRODUCTRETAILPRICE END AS SaleUnitPrice,
       ROUND(Dim_Product.ProductCost * SD.SalesQuantity,2) AS SaleExtendedCost,
       ROUND(SD.SalesAmount - SaleExtendedCost,2) AS SALE_TOTAL_PROFIT
       
    FROM STAGE_SALESHEADER AS SH
    
    INNER JOIN STAGE_SALESDETAIL AS SD 
    ON SH.SalesHeaderID = SD.SalesHeaderID
    
    INNER JOIN Dim_Product
    ON SD.ProductID = Dim_Product.DimProductID
    
    INNER JOIN Dim_Channel
    ON SH.ChannelID = Dim_Channel.DimChannelID
    
    LEFT JOIN Dim_Store 
    ON SH.StoreID = Dim_Store.DIMSTOREID
    
    LEFT JOIN Dim_Reseller 
    ON SH.ResellerID = Dim_Reseller.SourceResellerID
    
    LEFT JOIN Dim_Customer 
    ON SH.CustomerID = Dim_Customer.SourceCustomerID
    
    INNER JOIN Dim_Date
    ON to_date(RIGHT(SH.date, 8), 'YY-MM-DD') = Dim_Date.date;
    
    
    
select count (*) from FACT_SalesActual  -- verification of Count = 187320