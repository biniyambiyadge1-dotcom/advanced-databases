-- ============================================================
-- FILE: 06_isolation_levels.sql
-- SECTION: Concurrency Problems & Isolation Levels
-- CONTRIBUTOR: HUSSEN OMERE | ID: MTUUR/7787/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- ============================================================
-- CONCURRENCY PROBLEM 1: LOST UPDATE
-- Two transactions read the same stock value and both write.
-- One update overwrites the other → stock goes to -1.
--
-- WITHOUT protection (DO NOT use this pattern):
--   Tx A reads stock=1, Tx B reads stock=1 (stale)
--   Tx A commits stock=0, Tx B commits stock=-1  ← OVERSOLD!
-- ============================================================

-- FIX: Use FOR UPDATE to lock the row before reading.
-- Transaction A acquires the lock:
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
SELECT stock
FROM Inventory
WHERE product_id = 1
FOR UPDATE;
-- Transaction B is now BLOCKED until A commits or rolls back.
-- After A commits (stock=0), B resumes and sees stock=0.
-- B's application code checks stock > 0 → cancels the order.
COMMIT;

-- ============================================================
-- CONCURRENCY PROBLEM 2: DIRTY READ
-- Transaction B reads data that Transaction A has not committed yet.
-- If A rolls back, B has used invalid (phantom) data.
--
-- FIX: Use READ COMMITTED isolation level.
-- READ COMMITTED ensures a transaction only sees data that
-- has already been permanently committed by other transactions.
-- ============================================================

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;
-- This transaction will only see committed inventory values.
-- It will never see a stock value from a rolled-back transaction.
SELECT stock
FROM Inventory
WHERE product_id = 1;
COMMIT;

-- ============================================================
-- CONCURRENCY PROBLEM 3: NON-REPEATABLE READ
-- Transaction A reads the same row twice and gets different values
-- because Transaction B committed a change in between.
-- This breaks reports and calculations that need stable data.
--
-- FIX: Use REPEATABLE READ or SERIALIZABLE isolation level.
-- ============================================================

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
-- First read: stock = 10
SELECT stock FROM Inventory WHERE product_id = 1;

-- Even if another transaction commits a stock change here,
-- the second read in this transaction still returns 10.

-- Second read: still returns 10 (consistent)
SELECT stock FROM Inventory WHERE product_id = 1;
COMMIT;

-- ============================================================
-- ISOLATION LEVEL SUMMARY TABLE
-- +-----------------------+-------------+-----------------+--------------+
-- | Level                 | Dirty Read  | Non-Repeat Read | Phantom Read |
-- +-----------------------+-------------+-----------------+--------------+
-- | READ COMMITTED        | Prevented   | Possible        | Possible     |
-- | REPEATABLE READ       | Prevented   | Prevented       | Possible     |
-- | SERIALIZABLE          | Prevented   | Prevented       | Prevented    |
-- +-----------------------+-------------+-----------------+--------------+
-- ============================================================

-- ============================================================
-- PRACTICAL USAGE IN E-COMMERCE:
--
-- READ COMMITTED → Product browsing & catalog display
-- (minor inconsistencies acceptable; performance is priority)
--
-- SERIALIZABLE → Checkout, payment, inventory decrement
-- (strict correctness required; no overselling allowed)
-- ============================================================

-- READ COMMITTED example: product browsing
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;
SELECT p.name, p.price, i.stock
FROM Products p
JOIN Inventory i ON p.product_id = i.product_id
WHERE p.category_id = 1
  AND i.stock > 0;
COMMIT;

-- SERIALIZABLE example: checkout and payment processing
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
SELECT stock
FROM Inventory
WHERE product_id = 1
FOR UPDATE;

UPDATE Inventory
SET stock = stock - 1
WHERE product_id = 1
  AND stock > 0;

INSERT INTO Orders (order_id, customer_id, total, status)
VALUES (6, 1, 15000, 'Pending');

INSERT INTO Payments (payment_id, order_id, method, encrypted_reference, status)
VALUES (6, 6, 'Telebirr',
        AES_ENCRYPT('TELE-TXN-56789', 'platform_secret_key_256bit'),
        'Pending');
COMMIT;
