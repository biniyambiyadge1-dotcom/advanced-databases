-- ============================================================
-- FILE: 01_create_tables.sql
-- SECTION: Database Schema (DDL - Table Creation)
-- CONTRIBUTOR: AFRANO KINATO | ID: MTUUR/8919/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- Create Customers table
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name        VARCHAR(100),
    email       VARCHAR(150),
    phone       VARBINARY(255),   -- Stores AES-encrypted phone number
    city        VARCHAR(100),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Categories table
CREATE TABLE Categories (
    category_id   INT PRIMARY KEY,
    category_name VARCHAR(100)
);

-- Create Products table
CREATE TABLE Products (
    product_id  INT PRIMARY KEY,
    name        VARCHAR(100),
    category_id INT,
    price       DECIMAL(10,2),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- Create Inventory table
CREATE TABLE Inventory (
    product_id INT PRIMARY KEY,
    stock      INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Create Orders table
CREATE TABLE Orders (
    order_id    INT PRIMARY KEY,
    customer_id INT,
    total       DECIMAL(10,2),
    status      VARCHAR(50),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Create Order_Items table
CREATE TABLE Order_Items (
    order_item_id INT PRIMARY KEY,
    order_id      INT,
    product_id    INT,
    quantity      INT,
    FOREIGN KEY (order_id)   REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Create Payments table
CREATE TABLE Payments (
    payment_id           INT PRIMARY KEY,
    order_id             INT,
    method               VARCHAR(50),
    encrypted_reference  VARBINARY(255),  -- AES-encrypted transaction reference
    status               VARCHAR(50),
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- Create User_Accounts table (for login/security)
CREATE TABLE User_Accounts (
    account_id      INT PRIMARY KEY AUTO_INCREMENT,
    username        VARCHAR(100) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,   -- Stores bcrypt/SHA2 hash (never plain text)
    customer_id     INT,
    failed_attempts INT DEFAULT 0,
    locked_until    TIMESTAMP NULL,
    last_login      TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Create Audit_Log table
CREATE TABLE Audit_Log (
    log_id     INT PRIMARY KEY AUTO_INCREMENT,
    user_id    INT NOT NULL,
    username   VARCHAR(100),
    action     VARCHAR(100) NOT NULL,
    table_name VARCHAR(50),
    record_id  INT,
    old_value  TEXT,
    new_value  TEXT,
    ip_address VARCHAR(45),
    status     ENUM('SUCCESS', 'FAILED') DEFAULT 'SUCCESS',
    timestamp  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User_Accounts(account_id)
);
