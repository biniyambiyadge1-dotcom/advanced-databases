-- ============================================================
-- FILE: 02_insert_data.sql
-- SECTION: Data Insertion (DML - Sample Data)
-- CONTRIBUTOR: HAMDU IDRIS | ID: MTUUR/8293/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- Insert Categories
INSERT INTO Categories (category_id, category_name) VALUES
(1, 'Electronics'),
(2, 'Fashion');

SELECT * FROM Categories;

-- Insert Customers (phone stored as AES-encrypted binary)
INSERT INTO Customers (customer_id, name, email, phone, city) VALUES
(1, 'Biniyam', 'biniyam@example.com', AES_ENCRYPT('0912345678', 'platform_secret_key_256bit'), 'Addis Ababa'),
(2, 'Baye',    'baye@example.com',    AES_ENCRYPT('0923456789', 'platform_secret_key_256bit'), 'Adama'),
(3, 'Hamidu',  'hamidu@example.com',  AES_ENCRYPT('0934567890', 'platform_secret_key_256bit'), 'Hawassa');

SELECT * FROM Customers;

-- Insert Products
INSERT INTO Products (product_id, name, category_id, price) VALUES
(1, 'Laptop', 1, 15000),
(2, 'Phone',  1, 8000),
(3, 'Shoes',  2, 1200);

SELECT * FROM Products;

-- Insert Inventory
INSERT INTO Inventory (product_id, stock) VALUES
(1, 10),
(2, 20),
(3, 50);

SELECT * FROM Inventory;

-- Insert Orders
INSERT INTO Orders (order_id, customer_id, total, status) VALUES
(1, 1, 8000,  'Delivered'),
(2, 2, 15000, 'Pending');

SELECT * FROM Orders;

-- Insert Order_Items
INSERT INTO Order_Items (order_item_id, order_id, product_id, quantity) VALUES
(1, 1, 2, 1),
(2, 2, 1, 1);

SELECT * FROM Order_Items;

-- Insert Payments (payment reference stored as AES-encrypted binary)
INSERT INTO Payments (payment_id, order_id, method, encrypted_reference, status) VALUES
(1, 1, 'Telebirr',         AES_ENCRYPT('09-1234-5678-transaction-ref', 'platform_secret_key_256bit'), 'Completed'),
(2, 2, 'Cash on Delivery', AES_ENCRYPT('COD-ORDER-002',                'platform_secret_key_256bit'), 'Pending');

SELECT * FROM Payments;

-- Insert User_Accounts (passwords stored as SHA2 hash - never plain text)
INSERT INTO User_Accounts (account_id, username, password_hash, customer_id) VALUES
(1, 'biniyam_aa', SHA2('password123', 256), 1),
(2, 'baye_adama', SHA2('securepass',  256), 2),
(3, 'hamidu_hw',  SHA2('mypassword',  256), 3);

-- Insert Audit_Log
INSERT INTO Audit_Log (log_id, user_id, username, action, table_name, record_id, status) VALUES
(1, 1, 'biniyam_aa', 'Placed Order',       'Orders',   1, 'SUCCESS'),
(2, 1, 'biniyam_aa', 'Payment Completed',  'Payments', 1, 'SUCCESS'),
(3, 2, 'baye_adama', 'Created Order',       'Orders',   2, 'SUCCESS');

SELECT * FROM Audit_Log;
