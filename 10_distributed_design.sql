-- ============================================================
-- FILE: 10_distributed_design.sql
-- SECTION: Distributed Database Design
-- CONTRIBUTOR: ETHIOPIA WORKU | ID: MTUUR/8567/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- ============================================================
-- DISTRIBUTED DATABASE ARCHITECTURE OVERVIEW
--
-- The e-commerce platform distributes data across 3 nodes:
--
--   Node 1 (Central Hub) → Addis Ababa
--   Node 2 (East Node)   → Adama
--   Node 3 (South Node)  → Hawassa
--
-- Strategy:
--   Transactional tables (Orders, Payments) → Horizontally Sharded
--   Reference tables (Products, Categories) → Fully Replicated
-- ============================================================

-- ============================================================
-- HORIZONTAL FRAGMENTATION (SHARDING)
-- Orders and Payments are partitioned by city (shipping_city).
-- Each regional node stores only its local city's orders.
-- This minimizes latency: an Addis Ababa customer's data
-- stays on the Addis Ababa node.
-- ============================================================

-- Shard 1: Orders belonging to Addis Ababa customers
-- (Stored on the Addis Ababa Hub node)
CREATE VIEW shard_orders_addis_ababa AS
SELECT o.*
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
WHERE c.city = 'Addis Ababa';

-- Shard 2: Orders belonging to Adama customers
-- (Stored on the Adama Edge node)
CREATE VIEW shard_orders_adama AS
SELECT o.*
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
WHERE c.city = 'Adama';

-- Shard 3: Orders belonging to Hawassa customers
-- (Stored on the Hawassa Edge node)
CREATE VIEW shard_orders_hawassa AS
SELECT o.*
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
WHERE c.city = 'Hawassa';

-- ============================================================
-- FULL REPLICATION: Products & Categories
-- Product catalog is READ-HEAVY and rarely updated.
-- All three nodes keep a complete copy.
-- During a holiday sale, thousands of local users can browse
-- without any cross-region network calls.
--
-- Note: Replication itself is configured at the database server
-- level (MySQL replication config / PostgreSQL streaming),
-- not in SQL. The statements below document the design intent.
-- ============================================================

/*
  REPLICATION TOPOLOGY:
  ┌─────────────────────────────────────────────────┐
  │           Multi-Master (Peer-to-Peer)            │
  │  Addis Ababa ←→ Adama ←→ Hawassa (bidirectional)│
  │  Used for: inventory updates, new product listings│
  └─────────────────────────────────────────────────┘
  ┌─────────────────────────────────────────────────┐
  │        Master-Slave within each city             │
  │  Primary node → handles all local writes         │
  │  Read replicas → absorb browsing traffic         │
  └─────────────────────────────────────────────────┘
*/

-- ============================================================
-- DISTRIBUTED TRANSACTION: Two-Phase Commit (2PC)
-- Used for payment processing across regional nodes.
-- Guarantees strong consistency: all nodes commit together
-- or all nodes roll back together. No partial payments.
--
-- Phase 1 (Prepare): coordinator asks all nodes "can you commit?"
-- Phase 2 (Commit):  all nodes confirm → coordinator sends COMMIT
--
-- MySQL XA Transaction syntax for 2PC:
-- ============================================================

-- Start a distributed transaction (XA = eXtended Architecture)
XA START 'payment_txn_001';

INSERT INTO Payments (payment_id, order_id, method, encrypted_reference, status)
VALUES (
    20, 1, 'Telebirr',
    AES_ENCRYPT('XA-TXN-001-REF', 'platform_secret_key_256bit'),
    'Completed'
);

-- Phase 1: Prepare (node signals it is ready to commit)
XA END   'payment_txn_001';
XA PREPARE 'payment_txn_001';

-- Phase 2: Commit (coordinator confirms all nodes are ready)
XA COMMIT 'payment_txn_001';

-- If any node fails during prepare:
-- XA ROLLBACK 'payment_txn_001';

-- ============================================================
-- EVENTUAL CONSISTENCY: Saga Pattern
-- Used for long-running workflows like order fulfillment.
-- Each step is a local transaction. If one step fails,
-- compensating transactions undo prior steps.
--
-- Order Saga steps:
--   1. Reserve Inventory  → local commit on Inventory node
--   2. Process Payment    → local commit on Payments node
--   3. Confirm Order      → local commit on Orders node
--   4. Notify Shipping    → local commit on Logistics node
--
-- If Step 3 fails: compensating tx refunds payment (Step 2 undo)
--                  and restores stock (Step 1 undo).
-- ============================================================

-- Step 1: Reserve inventory (local transaction on inventory node)
BEGIN;
UPDATE Inventory
SET stock = stock - 1
WHERE product_id = 1 AND stock > 0;
COMMIT;

-- Step 2: Process payment (local transaction on payment node)
BEGIN;
INSERT INTO Payments (payment_id, order_id, method, encrypted_reference, status)
VALUES (21, 5, 'Telebirr',
        AES_ENCRYPT('SAGA-TXN-21', 'platform_secret_key_256bit'),
        'Completed');
COMMIT;

-- Step 3: Confirm order (local transaction on orders node)
BEGIN;
UPDATE Orders
SET status = 'Confirmed'
WHERE order_id = 5;
COMMIT;

-- Compensating transaction if Step 3 fails (undo Step 1):
-- BEGIN;
-- UPDATE Inventory SET stock = stock + 1 WHERE product_id = 1;
-- COMMIT;

-- ============================================================
-- CAP THEOREM DECISIONS
--
-- Checkout & Payments → CP (Consistency + Partition Tolerance)
--   Trade-off: if Hawassa-to-Addis link drops, checkout fails.
--   Justification: rejecting a checkout is safer than overselling.
--
-- Product Browsing → AP (Availability + Partition Tolerance)
--   Trade-off: price updates may be visible 1-2 min late.
--   Justification: thousands of shoppers must browse smoothly.
-- ============================================================
