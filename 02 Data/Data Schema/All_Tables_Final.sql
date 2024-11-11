-- Create New Table PlantConstraints
CREATE TABLE PlantConstraints (
    Plant_Code VARCHAR(26),
    Cost_Per_Unit NUMBER(38),
    Daily_Capacity NUMBER(38),
    Product_ID NUMBER(38),
    Customer VARCHAR(26),
    Ports VARCHAR(26)
);

-- Insert Into PlantConstraints Table Data From WhCosts
INSERT INTO PlantConstraints (PlantConstraints.Plant_Code, PlantConstraints.Cost_Per_Unit)
SELECT WhCosts.Plant_Code, WhCosts.Cost_Per_Unit
FROM WhCosts;

--Insert Into PlantConstraints Table Data From WhCapacities
INSERT INTO PlantConstraints (PlantConstraints.Plant_Code, PlantConstraints.Daily_Capacity)
SELECT WhCapacities.Plant_Code, WhCapacities.Daily_Capacity
FROM WhCapacities;

--Insert Into PlantConstraints Table Data From VmiCustomers
INSERT INTO PlantConstraints (PlantConstraints.Plant_Code, 
PlantConstraints.Customer)
SELECT VmiCustomers.Plant_Code, VmiCustomers.Customer
FROM VmiCustomers;

--Insert Into PlantConstraints Table Data From ProductsPerPlant
INSERT INTO PlantConstraints (PlantConstraints.Plant_Code,
PlantConstraints.Product_ID)
SELECT ProductsPerPlant.Plant_Code, ProductsPerPlant.Product_ID
FROM ProductsPerPlant;

--Insert Into PlantConstraints Table Data From PlantPorts
INSERT INTO PlantConstraints (PlantConstraints.Plant_Code,
PlantConstraints.Ports)
SELECT PlantPorts.Plant_Code, PlantPorts.Ports
FROM PlantPorts;

--Create a Sequence to generate the Numbers
CREATE SEQUENCE Seq_X
START WITH 1
INCREMENT BY 1;

-- Add New Column to Table
ALTER TABLE PlantConstraints
ADD (PlantCode_Constraint_ID NUMBER (38));

-- Populate the New Column
UPDATE PlantConstraints
SET PlantCode_Constraint_ID = Seq_X.NEXTVAL;

-- Drop the Old Tables
DROP TABLE WhCosts;
DROP TABLE WhCapacities;
DROP TABLE VmiCustomers;
DROP TABLE ProductsPerPlant;
DROP TABLE PlantPorts;

-- Add New Column to Table
ALTER TABLE FreightRates
ADD (Freight_Rates_ID NUMBER (38));

-- Populate the New Column
UPDATE FreightRates
SET Freight_Rates_ID = Seq_X.NEXTVAL;

--Create PlantProdCust Table
CREATE TABLE PlantProdCust (
    PlantProdCust_ID   NUMBER(38),
    Plant_Code VARCHAR(26),
    Product_ID NUMBER(38),
    Customer VARCHAR(26)
);

--Insert OrderList Data Into PlantProdCust Table
INSERT INTO PlantProdCust (PlantProdCust.Plant_Code, PlantProdCust.Product_ID,
PlantProdCust.Customer)
SELECT OrderList.Plant_Code, OrderList.Product_ID, OrderList.Customer
FROM OrderList;

-- Insert PlantConstraints Data Into PlantProdCust Table
INSERT INTO PlantProdCust (PlantProdCust.Plant_Code, PlantProdCust.Product_ID,
PlantProdCust.Customer)
SELECT PlantConstraints.Plant_Code, PlantConstraints.Product_ID, PlantConstraints.Customer
FROM PlantConstraints;

-- Replace NULL Values in PlantProdCust.Product_ID, PlantProdCust.Customer, 
--Plant Constraints.Product_ID, PlantConstraints.Customer With The Numeric Value 0
UPDATE PlantProdCust SET Product_ID=0 WHERE Product_ID IS NULL;
UPDATE PlantProdCust SET Customer=0 WHERE Customer IS NULL;
UPDATE PlantConstraints SET Customer=0 WHERE Customer IS NULL;
UPDATE PlantConstraints SET Product_ID=0 WHERE Product_ID IS NULL;

-- Remove Duplicate Rows in PlantProdCust
CREATE OR REPLACE TABLE PlantProdCust_Deduped AS
SELECT  PlantProdCust_ID, Plant_Code, Product_ID, Customer
FROM (
    SELECT  PlantProdCust_ID, Plant_Code, Product_ID, Customer,
           ROW_NUMBER() OVER (PARTITION BY Plant_Code, Product_ID, Customer ORDER BY PlantProdCust_ID) AS row_num
    FROM PlantProdCust
)
WHERE row_num = 1;

DROP TABLE PlantProdCust;

ALTER TABLE PlantProdCust_Deduped RENAME TO PlantProdCust;


--Populate The Primary Key Column
UPDATE PlantProdCust SET PlantProdCust_ID = Seq_X.NEXTVAL;

-- Add PlantProdCust_ID to OrderList
ALTER TABLE OrderList
ADD PlantProdCust_ID NUMBER(38);

-- Populate Foreign Key in OrderList Correctly
MERGE INTO OrderList AS A
USING PlantProdCust AS B
ON A.Plant_Code = B.Plant_Code
   AND A.Product_ID = B.Product_ID
   AND A.Customer = B.Customer
WHEN MATCHED THEN
   UPDATE SET A.PlantProdCust_ID = B.PlantProdCust_ID;

-- Drop Plant_Code, Product_ID & Customer Columns From OrderList
ALTER TABLE OrderList DROP COLUMN Plant_Code;
ALTER TABLE OrderList DROP COLUMN Product_ID;
ALTER TABLE OrderList DROP COLUMN Customer;

-- Add PlantProdCust_ID to PlantConstraints
ALTER TABLE PlantConstraints
ADD PlantProdCust_ID NUMBER (38);

-- Populate Foreign Key in PlantConstraints Correctly
MERGE INTO PlantConstraints AS A
USING PlantProdCust AS B
ON A.Plant_Code = B.Plant_Code
   AND A.Product_ID = B.Product_ID
   AND A.Customer = B.Customer
WHEN MATCHED THEN
   UPDATE SET A.PlantProdCust_ID = B.PlantProdCust_ID;

--Drop Plant_Code, Product_ID, & Customer Columns From PlantConstraints
ALTER TABLE PlantConstraints DROP COLUMN Plant_Code;
ALTER TABLE PlantConstraints DROP COLUMN Product_ID;
ALTER TABLE PlantConstraints DROP COLUMN Customer;

-- Create PortCarrier Table
CREATE TABLE PortCarrier (
    PortCarrier_ID NUMBER(38),
    Carrier        VARCHAR(26),
    Orig_Port      VARCHAR(26),
    Dest_Port      VARCHAR(26),
    Service_Level  VARCHAR(26)
);

-- Insert OrderList Data Into PortCarrier Table
INSERT INTO PortCarrier (PortCarrier.Carrier, PortCarrier.Orig_Port, PortCarrier.Dest_Port, 
PortCarrier.Service_Level)
SELECT OrderList.Carrier, OrderList.Orig_Port, OrderList.Dest_Port, OrderList.Service_Level 
FROM OrderList;

-- Insert FreightRates Data Into PortCarrier Table
INSERT INTO PortCarrier (PortCarrier.Carrier, PortCarrier.Orig_Port, PortCarrier.Dest_Port, 
PortCarrier.Service_Level)
SELECT FreightRates.Carrier, FreightRates.Orig_Port, FreightRates.Dest_Port, 
FreightRates.Service_Level
FROM FreightRates;

-- Remove Duplicate Rows in PortCarrier
CREATE OR REPLACE TABLE PortCarrier_Deduped AS
SELECT PortCarrier_ID, Carrier, Orig_Port, Dest_Port, Service_Level
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Carrier, Orig_Port, Dest_Port, Service_Level ORDER BY Carrier) AS row_num
    FROM PortCarrier
)
WHERE row_num = 1;

DROP TABLE PortCarrier;
ALTER TABLE PortCarrier_Deduped RENAME TO PortCarrier;

-- Populate The Primary Key Column
 UPDATE PortCarrier SET PortCarrier_ID = Seq_X.NEXTVAL;

-- Add PortCarrier_ID to OrderList
ALTER TABLE OrderList
ADD PortCarrier_ID NUMBER (38);

-- Populate Foreign Key in OrderList Correctly
MERGE INTO OrderList AS A
USING PortCarrier AS B
ON A.Carrier = B.Carrier
   AND A.Orig_Port = B.Orig_Port
   AND A.Dest_Port = B.Dest_Port
   AND A.Service_Level = B.Service_Level
WHEN MATCHED THEN
   UPDATE SET A.PortCarrier_ID = B.PortCarrier_ID;

-- Drop Carrier, Orig Port, Service_Level & Dest_Port Columns from OrderList
ALTER TABLE OrderList DROP COLUMN Orig_Port;
ALTER TABLE OrderList DROP COLUMN Dest_Port;
ALTER TABLE OrderList DROP COLUMN Carrier;
ALTER TABLE OrderList DROP COLUMN Service_Level;

-- Add PortCarrier_ID to FreightRates
ALTER TABLE FreightRates
ADD PortCarrier_ID NUMBER(38);

-- Populate Foreign Key in FreightRates Correctly
MERGE INTO FreightRates AS A
USING PortCarrier AS B
ON A.Carrier = B.Carrier
   AND A.Orig_Port = B.Orig_Port
   AND A.Dest_Port = B.Dest_Port
   AND A.Service_Level = B.Service_Level
WHEN MATCHED THEN
   UPDATE SET A.PortCarrier_ID = B.PortCarrier_ID;

-- Drop Carrier, Orig_Port, Service_Level & Dest Port Columns From OrderList
ALTER TABLE FreightRates DROP COLUMN Orig_Port;
ALTER TABLE FreightRates DROP COLUMN Dest_Port;
ALTER TABLE FreightRates DROP COLUMN Carrier;
ALTER TABLE FreightRates DROP COLUMN Service_Level;

-- Create Fact Table
CREATE TABLE FactTable (
    PlantCode_Constraint_ID NUMBER(38),
    Order_ID                NUMBER(38),
    Freight_Rates_ID        NUMBER(38),
    Min_Weight_Quant        NUMBER(38),
    Max_Weight_Quant        NUMBER(38),
    Min_Cost                NUMBER(38),
    Rate                    NUMBER(38),
    TPT_Day_Count           NUMBER(38),
    Cost_Per_Unit           NUMBER(38),
    Daily_Capacity          NUMBER(38),
    Ship_Ahead_Day_Count    NUMBER(38),
    Ship_Late_Day_Count     NUMBER(38),
    Unit_Quant              NUMBER(38),
    Weight                  NUMBER(38)
);

-- Insert Into FactTable Data From FreightRates
INSERT INTO FactTable (Freight_Rates_ID, Min_Weight_Quant, Max_Weight_Quant, Min_Cost, Rate, TPT_Day_Count)
SELECT 
    Freight_Rates_ID,
    TO_NUMBER(REPLACE(REPLACE(Min_Weight_Quant, ',', ''), '$', '')) AS Min_Weight_Quant,
    TO_NUMBER(REPLACE(REPLACE(Max_Weight_Quant, ',', ''), '$', '')) AS Max_Weight_Quant,
    TO_NUMBER(REPLACE(REPLACE(Min_Cost, ',', ''), '$', '')) AS Min_Cost,
    TO_NUMBER(REPLACE(REPLACE(Rate, ',', ''), '$', '')) AS Rate,
    TPT_Day_Count
FROM FreightRates;

-- Insert Into FactTable Data From PlantConstraints
INSERT INTO FactTable (FactTable.PlantCode_Constraint_ID, FactTable.Cost_Per_Unit, 
FactTable.Daily_Capacity)
SELECT PlantConstraints.PlantCode_Constraint_ID, PlantConstraints.Cost_Per_Unit, 
PlantConstraints.Daily_Capacity
FROM PlantConstraints;

-- Insert Into FactTable Data From OrderList
INSERT INTO FactTable (FactTable.Order_ID, FactTable.Ship_Ahead_Day_Count, 
FactTable.Ship_Late_Day_Count, FactTable.Unit_Quant, FactTable.Weight, FactTable.TPT_Day_Count)
SELECT OrderList.Order_ID, OrderList.Ship_Ahead_Day_Count, OrderList.Ship_Late_Day_Count, 
OrderList.Unit_Quant, OrderList.Weight, OrderList.TPT_Day_Count
FROM OrderList;

-- Dropping Columns
ALTER TABLE FreightRates DROP (Min_Weight_Quant, Max_Weight_Quant, Min_Cost, Rate, TPT_Day_Count); 
ALTER TABLE PlantConstraints DROP (Cost_Per_Unit, Daily_Capacity);
ALTER TABLE OrderList DROP (TPT_Day_Count, Ship_Ahead_Day_Count, Ship_Late_Day_Count, Unit_Quant, Weight);

--Set the Primary Key
ALTER TABLE FreightRates ADD PRIMARY KEY (Freight_Rates_ID);
ALTER TABLE PlantConstraints ADD PRIMARY KEY (PlantCode_Constraint_ID);
ALTER TABLE PortCarrier ADD PRIMARY KEY (PortCarrier_ID);
ALTER TABLE OrderList ADD PRIMARY KEY (Order_ID);
ALTER TABLE PlantProdCust ADD PRIMARY KEY (PlantProdCust_ID);

-- Set The Foreign Keys in The FactTable
 ALTER TABLE FactTable
 ADD FOREIGN KEY (PlantCode_Constraint_ID)
 REFERENCES PlantConstraints(PlantCode_Constraint_ID);

ALTER TABLE FactTable
ADD FOREIGN KEY (Order_ID)
REFERENCES OrderList(Order_ID)
ENABLE NOVALIDATE;

ALTER TABLE FactTable
ADD FOREIGN KEY (Freight_Rates_ID)
REFERENCES FreightRates(Freight_Rates_ID);

-- Set The Foreign Keys in The Dimension Tables
ALTER TABLE FreightRates
ADD FOREIGN KEY (PortCarrier_ID)
REFERENCES PortCarrier(PortCarrier_ID);
ALTER TABLE PlantConstraints
ADD FOREIGN KEY (PlantProdCust_ID)
REFERENCES PlantProdCust(PlantProdCust_ID);
ALTER TABLE OrderList
ADD FOREIGN KEY (PortCarrier_ID)
REFERENCES PortCarrier(PortCarrier_ID);
ALTER TABLE OrderList
ADD FOREIGN KEY (PlantProdCust_ID)
REFERENCES PlantProdCust(PlantProdCust_ID);

-- Drop Order_Date from OrderList
ALTER TABLE OrderList DROP COLUMN Order_Date;
 
-- Create New Column, Plant_Location_ID, in PlantProdCust
ALTER TABLE PlantProdCust ADD Plant_Location_ID NUMBER(38);

-- Populate The Plant_Location_ID in PlantProdCust Correctly
MERGE INTO PlantProdCust AS A
USING Plant_Locations AS B
ON A.Plant_Code = B.Plant_Code
WHEN MATCHED THEN 
    UPDATE SET A.Plant_Location_ID = B.Plant_Location_ID;

-- Drop Ports From PlantConstraints 
ALTER TABLE PlantConstraints DROP COLUMN Ports;
-- Drop Orig_Port, Dest_Port From PortCarrier 
ALTER TABLE PortCarrier DROP COLUMN Orig_Port;
ALTER TABLE PortCarrier DROP COLUMN Dest_Port;
-- Drop Plant_Code From PlantProdCust 
ALTER TABLE PlantProdCust DROP COLUMN Plant_Code;

-- Create Month_Num, Month_Name, Quarter, & Year Columns in Table OrderList
ALTER TABLE OrderList ADD Order_Date DATE;
ALTER TABLE OrderList ADD Month_Num NUMBER(38);
ALTER TABLE OrderList ADD Month_Name VARCHAR2(26);
ALTER TABLE OrderList ADD Quarter NUMBER(38);
ALTER TABLE OrderList ADD Year_ NUMBER(38);

-- Insert Order_Date, Month_Num, Month_Name, Quarter, & Year Data From Table Dates Into Table OrderList
MERGE INTO OrderList AS A
USING Dates AS B
ON A.Order_ID = B.Order_ID
WHEN MATCHED THEN 
    UPDATE SET 
        A.Order_Date = B.Order_Date,
        A.Month_Num = B.Month_Num,
        A.Month_Name = B.Month_Name,
        A.Quarter = B.Quarter,
        A.Year_ = B.Year_;

-- Rename Year_ Column to Year
 ALTER TABLE ORDERLIST RENAME COLUMN YEAR_ TO YEAR;--- Drop Dates Table
 DROP TABLE DATES;

-- Add New Column to PlantProdCust, Customers_SH (Short-Hand)
ALTER TABLE PlantProdCust ADD Customers_SH VARCHAR(26);

-- Populate the Customers_SH Column
MERGE INTO PlantProdCust AS A
USING Customers_SH AS B
ON A.Customer = B.Customers
WHEN MATCHED THEN 
    UPDATE SET A.Customers_SH = B.Customers_SH;
 -- Drop the Customers_SH Table
DROP TABLE Customers_SH;

-- Drop the Customer Column in PlantProdCust
ALTER TABLE PlantProdCust DROP COLUMN Customer;
-- Change The Name of the Customers_SH Column in the PlantProdCust Table to Customer
ALTER TABLE PlantProdCust RENAME COLUMN "CUSTOMERS_SH" to Customer;

-- Set Primary Key for Port_Locations, Plant_Locations, Dest_Port_Locations, Orig_Port_Locations
ALTER TABLE Port_Locations ADD PRIMARY KEY (Port_Location_ID);
ALTER TABLE Plant_Locations ADD PRIMARY KEY (Plant_Location_ID);
ALTER TABLE Dest_Port_Locations ADD PRIMARY KEY (Dest_Port_Location_ID);
ALTER TABLE Orig_Port_Locations ADD PRIMARY KEY (Orig_Port_Location_ID);

-- Set Foreign Key in PlantProdCust
ALTER TABLE PlantProdCust ADD FOREIGN KEY (Plant_Location_ID)
REFERENCES Plant_Locations(Plant_Location_ID);
-- Set Foreign Key in PlantConstraints
ALTER TABLE PlantConstraints ADD FOREIGN KEY (Port_Location_ID)
REFERENCES Port_Locations(Port_Location_ID);
-- Set Foreign Key in PortCarrier [Orig_Port]
ALTER TABLE PortCarrier ADD FOREIGN KEY(Orig_Port_Location_ID)
REFERENCES Orig_Port_Locations(Orig_Port_Location_ID);
-- Set Foreign Key in PortCarrier [Dest_Port]
ALTER TABLE PortCarrier ADD FOREIGN KEY (Dest_Port_Location_ID)
REFERENCES Dest_Port_Locations(Dest_Port_Location_ID);
