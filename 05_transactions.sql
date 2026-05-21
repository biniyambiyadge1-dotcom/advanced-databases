-- ============================================================
-- FILE: 05_transactions.sql
-- SECTION: Transactions & Concurrency Control
-- CONTRIBUTOR: BEZAWIT BETROS | ID: MTUUR/7776/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
-- Step 1: Lock the product stock row to prevent overselling
SELECT stock
FROM Inventory
WHERE product_id = 2
FOR UPDATE;

-- Step 2: Decrement stock safely (only if stock > 0)
UPDATE Inventory
SET stock = stock - 1
WHERE product_id = 2
  AND stock > 0;

-- Step 3: Create the order record
INSERT INTO Orders (order_id, customer_id, total, status)
VALUES (3, 3, 8000, 'Pending');

-- Step 4: Create the order item record
INSERT INTO Order_Items (order_item_id, order_id, product_id, quantity)
VALUES (3, 3, 2, 1);

-- Step 5: Create the payment record
INSERT INTO Payments (payment_id, order_id, method, encrypted_reference, status)
VALUES (3, 3, 'Telebirr',
        AES_ENCRYPT('09-9876-txn-ref', 'platform_secret_key_256bit'),
        'Completed');

-- Step 6: Write to audit log
INSERT INTO Audit_Log (user_id, username, action, table_name, record_id, status)
VALUES (3, 'hamidu_hw', 'Placed Order', 'Orders', 3, 'SUCCESS');
COMMIT;  -- All 6 steps are permanently saved
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
-- Step 1: Lock the Laptop stock row
SELECT stock
FROM Inventory
WHERE product_id = 1
FOR UPDATE;

-- Step 2: Decrement inventory
UPDATE Inventory
SET stock = stock - 1
WHERE product_id = 1;

-- Step 3: Create order
INSERT INTO Orders (order_id, customer_id, total, status)
VALUES (4, 2, 15000, 'Pending');
ROLLBACK;  
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;

-- Lock row AND check stock in one step
SELECT stock
FROM Inventory
WHERE product_id = 1
FOR UPDATE;
UPDATE Inventory
SET stock = stock - 1
WHERE product_id = 1
  AND stock > 0;   

INSERT INTO Orders (order_id, customer_id, total, status)
VALUES (5, 1, 15000, 'Pending');

INSERT INTO Order_Items (order_item_id, order_id, product_id, quantity)
VALUES (5, 5, 1, 1);

INSERT INTO Payments (payment_id, order_id, method, encrypted_reference, status)
VALUES (5, 5, 'Bank Transfer',
        AES_ENCRYPT('CBE-TXN-88991', 'platform_secret_key_256bit'),
        'Pending');

COMMIT;
