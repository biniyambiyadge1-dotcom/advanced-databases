-- ============================================================
-- FILE: 03_normalization.sql
-- SECTION: Normalization (UNF → 1NF → 2NF → 3NF)
-- CONTRIBUTOR: BAYE ASNAKE | ID: MTUUR/8832/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- ============================================================
-- STEP 1: UNNORMALIZED FORM (UNF)
-- All data mixed in one flat table.
-- Violations: no PK, repeating groups, embedded product data.
-- ============================================================

CREATE TABLE Orders_Flat_UNF (
    OrderID       INT,
    CustomerName  VARCHAR(100),
    CustomerCity  VARCHAR(100),
    ProductName   VARCHAR(100),
    ProductPrice  DECIMAL(10,2),
    CategoryName  VARCHAR(100),
    Quantity      INT
    -- No primary key defined (UNF violation)
);

INSERT INTO Orders_Flat_UNF VALUES
(1, 'Biniyam', 'Addis Ababa', 'Phone',  8000,  'Electronics', 1),
(2, 'Baye',    'Adama',       'Laptop', 15000, 'Electronics', 1),
(3, 'Hamidu',  'Hawassa',     'Shoes',  1200,  'Fashion',     2),
(3, 'Hamidu',  'Hawassa',     'Phone',  8000,  'Electronics', 1);
-- Notice: Hamidu appears TWICE for Order 3 (repeating group violation)

SELECT * FROM Orders_Flat_UNF;

-- ============================================================
-- STEP 2: FIRST NORMAL FORM (1NF)
-- Each row is atomic and uniquely identified.
-- Composite PK: (OrderID, OrderItemID)
-- Remaining problems: partial dependencies still exist.
-- ============================================================

CREATE TABLE Orders_1NF (
    OrderID      INT,
    OrderItemID  INT,
    CustomerName VARCHAR(100),
    City         VARCHAR(100),
    ProductID    INT,
    ProductName  VARCHAR(100),
    Price        DECIMAL(10,2),
    Quantity     INT,
    PRIMARY KEY (OrderID, OrderItemID)   -- Composite PK fixes UNF
);

INSERT INTO Orders_1NF VALUES
(1, 1, 'Biniyam', 'Addis Ababa', 2, 'Phone',  8000,  1),
(2, 2, 'Baye',    'Adama',       1, 'Laptop', 15000, 1),
(3, 3, 'Hamidu',  'Hawassa',     3, 'Shoes',  1200,  2),
(3, 4, 'Hamidu',  'Hawassa',     2, 'Phone',  8000,  1);

SELECT * FROM Orders_1NF;

-- ============================================================
-- STEP 3: SECOND NORMAL FORM (2NF)
-- Remove partial dependencies:
--   CustomerName/City depend only on OrderID, not the full PK.
--   ProductName/Price depend only on ProductID, not the full PK.
-- Solution: split into separate tables.
-- ============================================================

CREATE TABLE Customers_2NF (
    CustomerID INT PRIMARY KEY,
    Name       VARCHAR(100),
    City       VARCHAR(100),
    created_at DATE
);

INSERT INTO Customers_2NF VALUES
(1, 'Biniyam', 'Addis Ababa', '2026-04-18'),
(2, 'Baye',    'Adama',       '2026-04-18'),
(3, 'Hamidu',  'Hawassa',     '2026-04-18');

CREATE TABLE Products_2NF (
    ProductID  INT PRIMARY KEY,
    Name       VARCHAR(100),
    CategoryID INT,
    Price      DECIMAL(10,2),
    created_at DATE
);

INSERT INTO Products_2NF VALUES
(1, 'Laptop', 1, 15000, '2026-04-18'),
(2, 'Phone',  1, 8000,  '2026-04-18'),
(3, 'Shoes',  2, 1200,  '2026-04-18');

CREATE TABLE Orders_2NF (
    OrderID    INT PRIMARY KEY,
    CustomerID INT,
    Total      DECIMAL(10,2),
    Status     VARCHAR(50),
    created_at DATE,
    FOREIGN KEY (CustomerID) REFERENCES Customers_2NF(CustomerID)
);

INSERT INTO Orders_2NF VALUES
(1, 1, 8000,  'Delivered', '2026-04-18'),
(2, 2, 15000, 'Pending',   '2026-04-18');

CREATE TABLE Order_Items_2NF (
    OrderItemID INT PRIMARY KEY,
    OrderID     INT,
    ProductID   INT,
    Price       DECIMAL(10,2),
    Qty         INT,
    FOREIGN KEY (OrderID)   REFERENCES Orders_2NF(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products_2NF(ProductID)
);

INSERT INTO Order_Items_2NF VALUES
(1, 1, 2, 8000,  1),
(2, 2, 1, 15000, 1);

-- ============================================================
-- STEP 4: THIRD NORMAL FORM (3NF) — FINAL SCHEMA
-- Remove transitive dependencies:
--   CategoryName depends on CategoryID, not ProductID.
--   Stock depends on a separate business cycle.
--   Payments and Audit_Log are independent concerns.
-- Solution: extract Categories, Inventory, Payments, Audit_Log.
-- ============================================================

-- Categories extracted from Products (eliminates transitive dependency)
CREATE TABLE Categories_3NF (
    CategoryID   INT PRIMARY KEY,
    CategoryName VARCHAR(100)
);

INSERT INTO Categories_3NF VALUES
(1, 'Electronics'),
(2, 'Fashion');

-- Products now references CategoryID FK only (no CategoryName stored here)
CREATE TABLE Products_3NF (
    ProductID  INT PRIMARY KEY,
    Name       VARCHAR(100),
    CategoryID INT,
    Price      DECIMAL(10,2),
    created_at DATE,
    FOREIGN KEY (CategoryID) REFERENCES Categories_3NF(CategoryID)
);

INSERT INTO Products_3NF VALUES
(1, 'Laptop', 1, 15000, '2026-04-18'),
(2, 'Phone',  1, 8000,  '2026-04-18'),
(3, 'Shoes',  2, 1200,  '2026-04-18');

-- Inventory extracted: stock has its own update lifecycle
CREATE TABLE Inventory_3NF (
    ProductID  INT PRIMARY KEY,
    Stock      INT,
    updated_at DATE,
    FOREIGN KEY (ProductID) REFERENCES Products_3NF(ProductID)
);

INSERT INTO Inventory_3NF VALUES
(1, 10, '2026-04-18'),
(2, 20, '2026-04-18'),
(3, 50, '2026-04-18');

-- Payments extracted: payment method/status independent of order attributes
CREATE TABLE Payments_3NF (
    PaymentID  INT PRIMARY KEY,
    OrderID    INT,
    Method     VARCHAR(50),
    Status     VARCHAR(50),
    created_at DATE
);

INSERT INTO Payments_3NF VALUES
(1, 1, 'Telebirr',         'Completed', '2026-04-18'),
(2, 2, 'Cash on Delivery', 'Pending',   '2026-04-18');

-- Audit_Log extracted: independent cross-cutting concern
CREATE TABLE Audit_Log_3NF (
    LogID      INT PRIMARY KEY,
    UserID     INT,
    Action     VARCHAR(100),
    TableName  VARCHAR(50),
    RecordID   INT,
    Timestamp  DATE
);

INSERT INTO Audit_Log_3NF VALUES
(1, 1, 'Placed Order',      'Orders',   1, '2026-04-18'),
(2, 1, 'Payment Completed', 'Payments', 1, '2026-04-18'),
(3, 2, 'Created Order',     'Orders',   2, '2026-04-18');

SELECT * FROM Categories_3NF;
SELECT * FROM Products_3NF;
SELECT * FROM Inventory_3NF;
SELECT * FROM Payments_3NF;
SELECT * FROM Audit_Log_3NF;
