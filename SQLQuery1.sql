
-- Create DimEmployee Table
CREATE TABLE DimEmployee (
    EmployeeID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
	DepartmentID int ,
	DepartmentName NVARCHAR(50),
    JobTitle NVARCHAR(50),
    HireDate DATE,
    Gender NVARCHAR(1),
    MaritalStatus NVARCHAR(1),
	primary key(EmployeeID,DepartmentID)
);
-- Populate DimEmployee Table
insert into project.dbo.DimEmployee(  
	EmployeeID,
    FirstName,
    LastName,
	DepartmentID,
	DepartmentName,
    JobTitle,
    HireDate,
    Gender,
    MaritalStatus)
SELECT 
    e.BusinessEntityID, 
    p.FirstName, 
    p.LastName, 
	D.DepartmentID,
	D.Name,
    e.JobTitle, 
    e.HireDate, 
    e.Gender, 
    e.MaritalStatus
FROM HumanResources.Employee e
JOIN Person.Person p ON p.BusinessEntityID = e.BusinessEntityID
join HumanResources.EmployeeDepartmentHistory EDH on EDH.BusinessEntityID=e.BusinessEntityID
join HumanResources.Department D on D.DepartmentID=EDH.DepartmentID
WHERE 
    e.JobTitle <> 'Buyer';

-- Create DimTraining Table
CREATE TABLE DimTraining (
    TrainingID INT PRIMARY KEY,
    TrainingName NVARCHAR(100),
	DepartmentID int,
    TrainingCategory NVARCHAR(50),
    TrainingLocation NVARCHAR(50),
    TrainingDuration INT
);

-- Populate DimTraining Table
insert into project.dbo.DimTraining( 
	TrainingID,
    TrainingName,
	DepartmentID,
    TrainingCategory,
    TrainingLocation ,
    TrainingDuration,
	)
SELECT 
    ROW_NUMBER() OVER (ORDER BY E.BusinessEntityID) AS TrainingID,
    'Training ' + CONVERT(NVARCHAR(5), ROW_NUMBER() OVER (ORDER BY E.BusinessEntityID)) AS TrainingName,
	D.DepartmentID,
    D.Name AS TrainingCategory,
    'Location ' + CONVERT(NVARCHAR(5),D.DepartmentID) AS TrainingLocation,
    20 + (D.DepartmentID % 10) AS TrainingDuration
FROM HumanResources.Employee E
JOIN HumanResources.EmployeeDepartmentHistory EDH ON E.BusinessEntityID = EDH.BusinessEntityID
JOIN HumanResources.Department D ON EDH.DepartmentID = D.DepartmentID  -- Assuming FullDateAlternateKey is a date column


-- Create DimManager Table
CREATE TABLE DimManager (
    ManagerID INT,
    ManagerName NVARCHAR(100),
	DepartmentID INT, 
    ManagerJobTitle NVARCHAR(50),
    ManagerHireDate DATE,
	primary key(ManagerID,DepartmentID)
);

-- Populate DimManager Table
insert into project.dbo.DimManager( 
	ManagerID ,
    ManagerName ,
	DepartmentID,
    ManagerJobTitle,
    ManagerHireDate )
SELECT 
     e.BusinessEntityID as  ManagerID,
    CONCAT(p.FirstName, ' ', p.LastName) AS ManagerName,
	D.DepartmentID,
    JobTitle AS ManagerJobTitle,
    HireDate AS ManagerHireDate
FROM HumanResources.Employee e
join Person.Person p on p.BusinessEntityID=e.BusinessEntityID
join HumanResources.EmployeeDepartmentHistory EDH on EDH.BusinessEntityID=e.BusinessEntityID
join HumanResources.Department D on D.DepartmentID=EDH.DepartmentID
WHERE JobTitle LIKE '%Manager%'


-- Create DimDepartment Table
CREATE TABLE DimDepartment (
    DepartmentID INT PRIMARY KEY,
    DepartmentName NVARCHAR(50),
    number_of_employees INT
   
);

-- Populate DimDepartment Table
insert into project.dbo.DimDepartment(
	DepartmentID ,
    DepartmentName ,
     number_of_employees 
	 )
SELECT
  d.DepartmentID AS DepartmentID,
  d.Name AS DepartmentName,
  COUNT(e.BusinessEntityID) AS NumberOfEmployees
FROM HumanResources.Department d
JOIN HumanResources.EmployeeDepartmentHistory EDH ON d.DepartmentID = EDH.DepartmentID
join HumanResources.Employee e on EDH.BusinessEntityID=e.BusinessEntityID
GROUP BY d.DepartmentID, d.Name;


-- Create DimJobRole Table
CREATE TABLE DimJobRole (
    JobRoleID INT PRIMARY KEY,
	DepartmentID INT,
    JobTitle NVARCHAR(50),
    EmployeeCount INT
);
-- Populate DimJobRole Table
insert into project.dbo.DimJobRole (
    JobRoleID ,
	DepartmentID,
    JobTitle,
    EmployeeCount
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY JobTitle) AS JobRoleID,
	D.DepartmentID,
    JobTitle,
    COUNT(*) AS EmployeeCount
FROM HumanResources.Employee e
join HumanResources.EmployeeDepartmentHistory EDH on EDH .BusinessEntityID=e.BusinessEntityID
join HumanResources.Department D  on EDH.DepartmentID=D.DepartmentID
GROUP BY e.JobTitle,D.DepartmentID;

-- Create FactManPower Table
CREATE TABLE FactManPower (
    FactManPowerID INT PRIMARY KEY,
    DepartmentID INT,
    DepartmentName NVARCHAR(50),
    ManagerID INT,
    ManagerName NVARCHAR(100),
    JobRoleID INT,
    JobTitle NVARCHAR(50),
    NumberOfEmployees INT,
    CONSTRAINT FK_Fact_man_power_DimManager FOREIGN KEY (ManagerID,DepartmentID) REFERENCES DimManager (ManagerID,DepartmentID),
	CONSTRAINT FK_FactPersonelSales_DimDepartment FOREIGN KEY (DepartmentID) REFERENCES DimDepartment (DepartmentID),
    CONSTRAINT FK_FactPersonelSales_DimJobRole FOREIGN KEY (JobRoleID) REFERENCES DimJobRole (JobRoleID),
	CONSTRAINT FK_FactPersonelSales_DimEmployee FOREIGN KEY (ManagerID,DepartmentID) REFERENCES DimEmployee(EmployeeID,DepartmentID)
);

-- Populate FactManPower Table
INSERT INTO FactManPower (
	FactManPowerID ,
    DepartmentID ,
    DepartmentName,
    ManagerID ,
    ManagerName,
    JobRoleID,
    JobTitle,
    NumberOfEmployees 
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY D.DepartmentID, M.ManagerID, JR.JobRoleID) AS FactManPowerID,
    D.DepartmentID,
	D.DepartmentName,
	M.ManagerID,
	M.ManagerName,
    JR.JobRoleID,
	JR.JobTitle,
    COUNT(*) AS NumberOfEmployees
FROM 
    DimDepartment D
JOIN 
    DimManager M ON D.DepartmentID=M.DepartmentID
JOIN 
    DimJobRole JR ON D.DepartmentID = JR.DepartmentID
JOIN 
    DimEmployee E ON JR.JobTitle = E.JobTitle
GROUP BY 
   D.DepartmentID,D.DepartmentName, M.ManagerID,M.ManagerName, JR.JobRoleID,JR.JobTitle;


-- Create DimSales Table
CREATE TABLE DimSales (
    SalesPersonID INT ,
    Quota DECIMAL(18, 2),
	QuotaDate Date,
    CommissionPct DECIMAL(18, 2),
	saleslastyear DECIMAL(18,2),
    currentTotalSales DECIMAL(18, 2),
	primary key(SalesPersonID,QuotaDate)
);
-- Populate DimSales Table
insert into project.dbo.DimSales( 
	SalesPersonID ,
    Quota ,
	QuotaDate,
    CommissionPct,
	saleslastyear ,
    currentTotalSales )
SELECT 
   SP.BusinessEntityID AS SalesPersonID,
    SQ.SalesQuota AS Quota,
	SQ.QuotaDate as QuotaDate,
    SP.CommissionPct,
	SP.SalesLastYear,
    SUM(SOH.TotalDue) AS currentTotalSales
FROM Sales.SalesPerson SP
LEFT JOIN Sales.SalesPersonQuotaHistory SQ ON SP.BusinessEntityID = SQ.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader SOH ON SP.BusinessEntityID = SOH.SalesPersonID
GROUP BY SP.BusinessEntityID, SQ.SalesQuota, SQ.QuotaDate,SP.CommissionPct,sp.SalesLastYear;


-- Create FactEmployeePerformance Table
CREATE TABLE FactEmployeePerformance (
    FactPersonelSalesID INT PRIMARY KEY,
    SalesPersonID INT,
	DepartmentID int ,
    Name NVARCHAR(100),
    HireDate DATE,
    Quota DECIMAL(18, 2),
    QuotaDate DATE,
    CommissionPct DECIMAL(18, 2),
    SalesLastYear DECIMAL(18, 2),
    CurrentTotalSales DECIMAL(18, 2),
    CONSTRAINT FK_FactEmployeePerformance_DimSales FOREIGN KEY (SalesPersonID, QuotaDate) REFERENCES DimSales(SalesPersonID, QuotaDate),
    CONSTRAINT FK_FactEmployeePerformance_DimEmployee FOREIGN KEY (SalesPersonID,DepartmentID) REFERENCES DimEmployee(EmployeeID,DepartmentID),
	CONSTRAINT FK_FactEmployeePerformance_DimDate FOREIGN KEY (QuotaDate) REFERENCES DimDate(fullDateAlternateKey )
);

drop table FactEmployeePerformance
-- Populate FactEmployeePerformance table
insert into project.dbo. FactEmployeePerformance(
	FactPersonelSalesID,
	SalesPersonID ,
	DepartmentID,
	name ,
	HireDate , 
	Quota,
	QuotaDate ,
    CommissionPct,
	saleslastyear,
    currentTotalSales )
SELECT 
	 ROW_NUMBER() OVER (ORDER BY e.EmployeeID ) AS FactPeronelSalesID,
    e.EmployeeID AS SalesPersonID,
	e.DepartmentID,
	e.FirstName,
	e.HireDate,
    S.Quota,
	d.fullDateAlternateKey as QuotaDate,
    S.CommissionPct,
	S.SalesLastYear,
    S.currentTotalSales
FROM DimSales S
JOIN DimEmployee e ON S.SalesPersonID=e.EmployeeID
join DimDate d on d.fullDateAlternateKey=S.QuotaDate


create table DimDate(
fullDateAlternateKey date PRIMARY KEY,
date_year int,
date_month int,
date_quarter int,
Day_Of_Week int,
Week_Of_Month int,
Day_Name NVARCHAR(20)
);

Declare @startdate datetime ='2010-01-01';
Declare @enddate datetime ='2014-12-31';
WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO DimDate (
        FullDateAlternateKey,
        date_year,
        date_month,
        date_quarter,
        Week_Of_Month,
        Day_Of_Week,
        Day_Name
    )
    VALUES (
        @StartDate,
        YEAR(@StartDate),
        MONTH(@StartDate),
        DATEPART(QUARTER, @StartDate),
        DATEPART(WEEK, @StartDate),
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate)
    );

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;




-- Create FactManagerSales Table
CREATE TABLE FactManagerSales (
	DepartmentID int,
    ManagerID INT,
	ManagerName NVARCHAR(50),
	JobTitle NVARCHAR(50),
	HireDate date,
	QuotaDate DATE,
	Quota DECIMAL(18, 2),
    TotalSales DECIMAL(18, 2),
    PRIMARY KEY (ManagerID,QuotaDate),
    CONSTRAINT FK_FactManagerSales_DimManager FOREIGN KEY (ManagerID,DepartmentID) REFERENCES DimManager (ManagerID,DepartmentID),
	CONSTRAINT FK_FactManagerSales_DimSales FOREIGN KEY (ManagerID,QuotaDate) REFERENCES DimSales (SalesPersonID,QuotaDate),
	CONSTRAINT FK_FactManagerSales_DimDate FOREIGN KEY (QuotaDate) REFERENCES DimDate(fullDateAlternateKey)
);

-- Populate FactManagerSales Table
INSERT INTO FactManagerSales (
    DepartmentID ,
    ManagerID ,
	ManagerName ,
	JobTitle ,
	HireDate,
	QuotaDate,
	Quota,
    TotalSales
)
SELECT
	m.DepartmentID,
    m.ManagerID,
	m.ManagerName,
	m.ManagerJobTitle,
	m.ManagerHireDate,
    d.fullDateAlternateKey as QuotaDate,
	s.Quota,
    s.currentTotalSales
FROM project.dbo.DimManager m
JOIN project.dbo.DimSales s ON m.ManagerID = s.SalesPersonID
join project.dbo.DimDate d on d.fullDateAlternateKey=s.QuotaDate



-- Create FactEmployeeTraining Table
CREATE TABLE FactEmployeeTraining (
   	TrainingID int,
	TrainingName nvarchar(50),
	DepartmentID int,
	DepartmentName nvarchar(50),
	ManagerID int,
    TrainingCategory nvarchar(50),
	TrainingDuration int ,
	TrainingLocation nvarchar(20),
	EmployeeID int,
	primary key(TrainingID,ManagerID,DepartmentName),
    FOREIGN KEY (EmployeeID,DepartmentID) REFERENCES DimEmployee (EmployeeID,DepartmentID),
    FOREIGN KEY (ManagerID,DepartmentID)REFERENCES DimManager (ManagerID,DepartmentID),
    FOREIGN KEY (DepartmentID) REFERENCES DimDepartment (DepartmentID),
    FOREIGN KEY (TrainingID) REFERENCES DimTraining(TrainingID)
);
-- Populate FactEmployeeTraining Table
INSERT INTO FactEmployeeTraining (
	TrainingID,
	TrainingName,
	DepartmentID,
	DepartmentName,
	ManagerID,
    TrainingCategory,
	TrainingDuration,
	TrainingLocation,
	EmployeeID
)
SELECT
	t.TrainingID,
	t.TrainingName,
	d.DepartmentID,
	d.DepartmentName,
	m.ManagerID,
    t.TrainingCategory,
	t.TrainingDuration,
	t.TrainingLocation,
	e.EmployeeID
FROM project.dbo.DimEmployee e
JOIN project.dbo.DimTraining t ON e.EmployeeID = t.TrainingID
join project.dbo.DimDepartment d on e.DepartmentID=d.DepartmentID
join project.dbo.DimManager m on m.DepartmentID=d.DepartmentID


--create DimProductSales
CREATE TABLE DimProductSales(
    ProductID INT,
    ProductName varchar(100),
    StandardCost money,
    listPrice money,
	SalesOrderID int ,
	OrderQty int ,
	ProductSubcategory NVARCHAR(255),
    ProductCategory NVARCHAR(255),
	OnlineOrderFlag int,
	primary key(ProductID,SalesOrderID)
);

--populate DimProductSales
insert into project.dbo.DimProductSales(
	ProductID,
	ProductName,
	StandardCost,
	listPrice,
	SalesOrderID,
	OrderQty,
	ProductSubcategory,
	ProductCategory,
	OnlineOrderFlag
)
select 
	pro.ProductID,
	pro.Name as ProductName,
	pro.StandardCost,
	pro.ListPrice,
	sod.SalesOrderID,
	sod.OrderQty,
	psc.Name AS ProductSubcategory,
	pc.Name AS ProductCategory,
	soh.OnlineOrderFlag
FROM Production.Product pro
join Production.ProductSubcategory psc on pro.ProductSubcategoryID=psc.ProductSubcategoryID
join Production.Productcategory pc on pc.ProductCategoryID=psc.ProductCategoryID
join sales.SalesOrderDetail sod on sod.ProductID=pro.ProductID
join sales.SalesOrderHeader soh on soh.SalesOrderID=sod.SalesOrderID


--create DimCustomer
 create table DimCustomer(
	CustomerID int,
	CustomerName nvarchar(50),
	TerritoryID int,
	salesPersonID int,
	AccountNumber nvarchar(40),
	SalesOrderID int,
	TotalDue decimal(18,2),
	AddressID int,
	CustomerEmailAddress nvarchar(50),
	PhoneNumber nvarchar(50),
	primary key(CustomerID,SalesOrderID,AddressID)
)

--populate DimCustomer
INSERT INTO project.dbo.DimCustomer (
    CustomerID,
	CustomerName,
	TerritoryID,
	AccountNumber,
	SalesOrderID,
	TotalDue,
	 AddressID,
	CustomerEmailAddress,
	PhoneNumber
)
SELECT
    c.CustomerID,
    concat(p.FirstName,' ',p.LastName) as CustomerName,
	c.TerritoryID,
	c.AccountNumber,
	soh.SalesOrderID,
	soh.TotalDue,
    BEA.AddressID,
	em.EmailAddress,
	ph.PhoneNumber
FROM Sales.Customer c
JOIN Person.BusinessEntityAddress BEA ON c.CustomerID = BEA.BusinessEntityID
join Person.Person p on p.BusinessEntityID=c.CustomerID
join person.EmailAddress em on em.BusinessEntityID=p.BusinessEntityID
join Person.PersonPhone ph on ph.BusinessEntityID=p.BusinessEntityID
join sales.SalesOrderHeader soh on soh.CustomerID=c.CustomerID
order by (CustomerID)


-- Create FactInternetSales Table
CREATE TABLE FactInternetSales (
    CustomerID int,
	AddressID int,
    ProductID int,
	ProductName nvarchar(50),
	ProductCategory nvarchar(50),
	ProductSubCategory nvarchar(50),
	SalesOrderID int,
	ListPrice decimal(18,2),
    TotalDue decimal(18,2),
	PRIMARY KEY(CustomerID, AddressID,ProductID,SalesOrderID),
	CONSTRAINT FK_FactInternetSales_DimCustomer FOREIGN KEY (CustomerID,SalesOrderID,AddressID) REFERENCES DimCustomer(CustomerID,SalesOrderID,AddressID),
	CONSTRAINT FK_FactInternetSales_DimProductSales FOREIGN KEY (ProductID,SalesOrderID) REFERENCES DimProductSales (ProductID,SalesOrderID)
);


INSERT INTO project.dbo.FactInternetSales (
  	CustomerID,
	AddressID,
    ProductID,
	ProductName,
	ProductCategory,
	ProductSubCategory,
	SalesOrderID,
	listPrice, 
	TotalDue
)

select 
	c.CustomerID,
	c.AddressID,
    ps.ProductID,
	ps.ProductName,
	ps.ProductCategory,
	ps.ProductSubCategory,
	ps.SalesOrderID,
	ps.listPrice, 
	c.TotalDue
from project.dbo.DimCustomer c
join project.dbo.DimProductSales ps on ps.SalesOrderID=c.SalesOrderID
where ps.OnlineOrderFlag = 1
