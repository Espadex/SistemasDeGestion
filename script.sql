-- /*
-- ============================================
-- A. CREAR BASE DE DATOS Y USARLA
-- ============================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'AdventureWorksDW')
  CREATE DATABASE AdventureWorksDW;
GO
USE AdventureWorksDW;
GO

-- ============================================
-- B. LIMPIEZA INICIAL (SI EXISTE ALGO)
-- ============================================

-- Eliminar tablas si existen (con chequeo de esquema)
IF OBJECT_ID('Ventas.FactVentas') IS NOT NULL DROP TABLE Ventas.FactVentas;
IF OBJECT_ID('Compras.FactCompras') IS NOT NULL DROP TABLE Compras.FactCompras;
IF OBJECT_ID('Ventas.DimCliente') IS NOT NULL DROP TABLE Ventas.DimCliente;
IF OBJECT_ID('Ventas.DimMetodoPago') IS NOT NULL DROP TABLE Ventas.DimMetodoPago;
IF OBJECT_ID('Compras.DimProveedor') IS NOT NULL DROP TABLE Compras.DimProveedor;
IF OBJECT_ID('Compras.DimMetodoEnvio') IS NOT NULL DROP TABLE Compras.DimMetodoEnvio;
IF OBJECT_ID('Dimensiones.DimProducto') IS NOT NULL DROP TABLE Dimensiones.DimProducto;
IF OBJECT_ID('Dimensiones.DimTiempo') IS NOT NULL DROP TABLE Dimensiones.DimTiempo;
IF OBJECT_ID('Dimensiones.DimEstado') IS NOT NULL DROP TABLE Dimensiones.DimEstado;
GO

-- Eliminar esquemas si existen
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Ventas') DROP SCHEMA Ventas;
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Compras') DROP SCHEMA Compras;
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Dimensiones') DROP SCHEMA Dimensiones;
GO

-- ============================================
-- C. CREACIÓN DE ESQUEMAS
-- ============================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Dimensiones')
BEGIN
    EXEC('CREATE SCHEMA Dimensiones;');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Compras')
BEGIN
    EXEC('CREATE SCHEMA Compras;');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Ventas')
BEGIN
    EXEC('CREATE SCHEMA Ventas;');
END
GO

-- ============================================
-- D. CREACIÓN DE DIMENSIONES COMPARTIDAS
-- ============================================

CREATE TABLE Dimensiones.DimProducto (
  ID_Producto INT PRIMARY KEY,
  NombreProducto NVARCHAR(100),
  Subcategoria NVARCHAR(50),
  Categoria NVARCHAR(50),
  Color NVARCHAR(15),
  Tamaño NVARCHAR(5),
  CostoEstandar DECIMAL(10,2),
  PrecioDeLista DECIMAL(10,2),
  Modelo NVARCHAR(50)
);

CREATE TABLE Dimensiones.DimTiempo (
  ID_Tiempo INT PRIMARY KEY,
  Fecha DATE,
  Año INT,
  Trimestre INT,
  Mes INT,
  NombreMes NVARCHAR(20),
  Dia INT,
  DiaDeLaSemana NVARCHAR(20),
  SemanaDelAño INT
);

CREATE TABLE Dimensiones.DimEstado (
  ID_Estado INT PRIMARY KEY,
  Estado NVARCHAR(50)
);

-- ============================================
-- E. DIMENSIONES ESPECÍFICAS
-- ============================================

CREATE TABLE Compras.DimProveedor (
  ID_Proveedor INT PRIMARY KEY,
  NombreProveedor NVARCHAR(100),
  Pais NVARCHAR(50),
  EstadoID INT,
  Ciudad NVARCHAR(50),
  FOREIGN KEY (EstadoID) REFERENCES Dimensiones.DimEstado(ID_Estado)
);

CREATE TABLE Compras.DimMetodoEnvio (
  ID_MetodoEnvio INT PRIMARY KEY,
  NombreMetodoEnvio NVARCHAR(50)
);

CREATE TABLE Ventas.DimCliente (
  ID_Cliente INT PRIMARY KEY,
  NombreCliente NVARCHAR(150),
  TipoCliente NVARCHAR(50),
  TerritorioVentas NVARCHAR(50),
  Pais NVARCHAR(50),
  EstadoID INT,
  Ciudad NVARCHAR(50),
  FOREIGN KEY (EstadoID) REFERENCES Dimensiones.DimEstado(ID_Estado)
);

CREATE TABLE Ventas.DimMetodoPago (
  ID_MetodoPago INT PRIMARY KEY,
  TipoTarjeta NVARCHAR(50)
);

-- ============================================
-- F. TABLAS DE HECHOS
-- ============================================

CREATE TABLE Compras.FactCompras (
  ID_Compra BIGINT PRIMARY KEY,
  ID_Producto INT,
  ID_Proveedor INT,
  ID_Tiempo INT,
  ID_MetodoEnvio INT,
  CantidadComprada INT,
  PrecioUnitario DECIMAL(10,2),
  -- REMOVED: CostoTotal AS (CantidadComprada * PrecioUnitario) PERSISTED,
  FOREIGN KEY (ID_Producto) REFERENCES Dimensiones.DimProducto(ID_Producto),
  FOREIGN KEY (ID_Proveedor) REFERENCES Compras.DimProveedor(ID_Proveedor),
  FOREIGN KEY (ID_Tiempo) REFERENCES Dimensiones.DimTiempo(ID_Tiempo),
  FOREIGN KEY (ID_MetodoEnvio) REFERENCES Compras.DimMetodoEnvio(ID_MetodoEnvio)
);

CREATE TABLE Ventas.FactVentas (
  ID_Venta BIGINT PRIMARY KEY,
  ID_Producto INT,
  ID_Cliente INT,
  ID_Tiempo INT,
  ID_MetodoPago INT,
  CantidadVendida INT,
  PrecioUnitario DECIMAL(10,2),
  -- REMOVED: IngresoTotal AS (CantidadVendida * PrecioUnitario) PERSISTED,
  CanalVenta NVARCHAR(50),
  FOREIGN KEY (ID_Producto) REFERENCES Dimensiones.DimProducto(ID_Producto),
  FOREIGN KEY (ID_Cliente) REFERENCES Ventas.DimCliente(ID_Cliente),
  FOREIGN KEY (ID_Tiempo) REFERENCES Dimensiones.DimTiempo(ID_Tiempo),
  FOREIGN KEY (ID_MetodoPago) REFERENCES Ventas.DimMetodoPago(ID_MetodoPago)
);
GO

-- */
-- ==============================================================================================

-- ============================================
-- F. CARGA DE DATOS (INSERT) – SOLO ETL CORREGIDO
-- ============================================

USE AdventureWorksDW;
GO

-- F.1 DimProducto (sin cambios)
INSERT INTO Dimensiones.DimProducto
SELECT
  p.ProductID,
  p.Name,
  psc.Name,
  pc.Name,
  p.Color,
  p.Size,
  p.StandardCost,
  p.ListPrice,
  pm.Name
FROM AdventureWorks2022.Production.Product p
LEFT JOIN AdventureWorks2022.Production.ProductSubcategory psc
  ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN AdventureWorks2022.Production.ProductCategory pc
  ON psc.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN AdventureWorks2022.Production.ProductModel pm
  ON p.ProductModelID = pm.ProductModelID;
GO

-- F.2 DimTiempo (sin cambios)
INSERT INTO Dimensiones.DimTiempo
SELECT DISTINCT
  CAST(CONVERT(CHAR(8), Fecha,112) AS INT),
  Fecha,
  YEAR(Fecha),
  DATEPART(QUARTER, Fecha),
  MONTH(Fecha),
  DATENAME(MONTH, Fecha),
  DAY(Fecha),
  DATENAME(WEEKDAY, Fecha),
  DATEPART(WEEK, Fecha)
FROM (
  SELECT OrderDate AS Fecha
    FROM AdventureWorks2022.Purchasing.PurchaseOrderHeader
  UNION
  SELECT OrderDate FROM AdventureWorks2022.Sales.SalesOrderHeader
) AS t;
GO

-- F.3 DimEstado (sin cambios)
INSERT INTO Dimensiones.DimEstado (ID_Estado, Estado)
SELECT DISTINCT
  sp.StateProvinceID,
  sp.Name
FROM AdventureWorks2022.Person.StateProvince sp;
GO

-- F.4 Compras – Proveedores y Método de Envío (Revised)
INSERT INTO Compras.DimProveedor
SELECT DISTINCT
    v.BusinessEntityID AS ID_Proveedor,
    v.Name AS NombreProveedor,
    cr.Name AS Pais,
    sp.StateProvinceID AS EstadoID,
    a.City AS Ciudad
FROM AdventureWorks2022.Purchasing.Vendor v
LEFT JOIN AdventureWorks2022.Person.BusinessEntityAddress bea
    ON v.BusinessEntityID = bea.BusinessEntityID
LEFT JOIN AdventureWorks2022.Person.Address a
    ON bea.AddressID = a.AddressID
LEFT JOIN AdventureWorks2022.Person.StateProvince sp
    ON a.StateProvinceID = sp.StateProvinceID
LEFT JOIN AdventureWorks2022.Person.CountryRegion cr
    ON sp.CountryRegionCode = cr.CountryRegionCode;
GO

-- Método de envío (sin cambios)
INSERT INTO Compras.DimMetodoEnvio
SELECT ShipMethodID, Name
FROM AdventureWorks2022.Purchasing.ShipMethod;
GO

-- F.5 Ventas – Clientes y Método de Pago
--    Incluimos todos los clientes, aunque no tengan dirección
INSERT INTO Ventas.DimCliente
SELECT DISTINCT
  c.CustomerID                                        AS ID_Cliente,
  COALESCE(pp.FirstName + ' ' + pp.LastName, st.Name) AS NombreCliente,
  CASE WHEN c.StoreID IS NULL THEN 'Persona' ELSE 'Tienda' END AS TipoCliente,
  s_terr.Name                                         AS TerritorioVentas,
  cr.Name                                             AS Pais,
  sp.StateProvinceID                                  AS EstadoID,
  addr.City                                           AS Ciudad
FROM AdventureWorks2022.Sales.Customer c
LEFT JOIN AdventureWorks2022.Person.BusinessEntityAddress bea
  ON bea.BusinessEntityID = COALESCE(c.PersonID, c.StoreID)
  AND bea.AddressTypeID = 2
LEFT JOIN AdventureWorks2022.Person.Address addr
  ON bea.AddressID = addr.AddressID
LEFT JOIN AdventureWorks2022.Person.StateProvince sp
  ON addr.StateProvinceID = sp.StateProvinceID
LEFT JOIN AdventureWorks2022.Person.CountryRegion cr
  ON sp.CountryRegionCode = cr.CountryRegionCode
LEFT JOIN AdventureWorks2022.Person.Person pp
  ON c.PersonID = pp.BusinessEntityID
LEFT JOIN AdventureWorks2022.Sales.Store st
  ON c.StoreID = st.BusinessEntityID
LEFT JOIN AdventureWorks2022.Sales.SalesTerritory s_terr
  ON c.TerritoryID = s_terr.TerritoryID;
GO

-- Métodos de pago (sin cambios)
INSERT INTO Ventas.DimMetodoPago
VALUES (0, 'No usa Tarjeta');
GO
INSERT INTO Ventas.DimMetodoPago (ID_MetodoPago, TipoTarjeta)
SELECT CreditCardID, CardType
FROM AdventureWorks2022.Sales.CreditCard;
GO

-- F.6 Hechos de Compras y Ventas (sin agregación)
INSERT INTO Compras.FactCompras
SELECT
  CAST(poh.PurchaseOrderID AS BIGINT) * 1000 + pod.PurchaseOrderDetailID AS ID_Compra,
  pod.ProductID,
  poh.VendorID,
  CAST(CONVERT(CHAR(8), poh.OrderDate,112) AS INT)                     AS ID_Tiempo,
  poh.ShipMethodID                                                      AS ID_MetodoEnvio,
  pod.OrderQty                                                          AS CantidadComprada,
  pod.UnitPrice                                                         AS PrecioUnitario
FROM AdventureWorks2022.Purchasing.PurchaseOrderHeader poh
JOIN AdventureWorks2022.Purchasing.PurchaseOrderDetail pod
  ON poh.PurchaseOrderID = pod.PurchaseOrderID;
GO

INSERT INTO Ventas.FactVentas
SELECT
  CAST(soh.SalesOrderID AS BIGINT) * 1000 + sod.SalesOrderDetailID AS ID_Venta,
  sod.ProductID                                                       AS ID_Producto,
  soh.CustomerID                                                      AS ID_Cliente,
  CAST(CONVERT(CHAR(8), soh.OrderDate,112) AS INT)                  AS ID_Tiempo,
  COALESCE(soh.CreditCardID, 0)                                       AS ID_MetodoPago,
  sod.OrderQty                                                        AS CantidadVendida,
  sod.UnitPrice                                                       AS PrecioUnitario,
  CASE WHEN soh.OnlineOrderFlag = 1 THEN 'Online' ELSE 'Tienda' END AS CanalVenta
FROM AdventureWorks2022.Sales.SalesOrderHeader soh
JOIN AdventureWorks2022.Sales.SalesOrderDetail sod
  ON soh.SalesOrderID = sod.SalesOrderID;
GO