-- ============================================================
-- FILE: 11_failure_recovery.sql
-- SECTION: Failure Recovery (WAL, Checkpointing, Backup, ARIES)
-- CONTRIBUTOR: HAMDU IDRIS | ID: MTUUR/8293/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- ============================================================
-- WRITE-AHEAD LOGGING (WAL)
-- Core Rule: Every change must be written to the WAL log file
-- BEFORE the modified data pages are written to disk.
--
-- How it protects our e-commerce system:
--   1. Customer places order via Telebirr.
--   2. Changes (order row, inventory decrement, payment record)
--      are instantly written to the WAL log on disk first.
--   3. Only after log write is confirmed does the DB update pages.
--   4. If a power failure occurs at any point, the log is safe.
--   5. On restart, WAL log is the authoritative source of truth.
-- ============================================================

-- Enable WAL mode (PostgreSQL - this is default in production):
-- ALTER SYSTEM SET wal_level = 'replica';
-- ALTER SYSTEM SET archive_mode = 'on';

-- MySQL equivalent - enable binary log (acts as WAL):
-- In my.cnf: log_bin = /var/log/mysql/mysql-bin.log

-- ============================================================
-- CHECKPOINTING
-- Periodically flushes dirty RAM pages to disk and writes a
-- CHECKPOINT record to the WAL. During crash recovery, the
-- system only replays WAL entries AFTER the last checkpoint,
-- dramatically reducing restart time.
-- ============================================================

-- MySQL: Force an immediate checkpoint
FLUSH TABLES WITH READ LOCK;
FLUSH LOGS;
UNLOCK TABLES;

-- PostgreSQL equivalent:
-- CHECKPOINT;

-- ============================================================
-- BACKUP STRATEGIES
-- Three complementary backup types for full data protection.
-- ============================================================

-- STRATEGY 1: Full Backup (Daily at 2:00 AM - 4:00 AM)
-- Captures the entire database as a snapshot.
-- MySQL shell command (run via cron job - not SQL):
/*
  mysqldump --all-databases \
            --single-transaction \
            --flush-logs \
            --master-data=2 \
            -u root -p \
            > /backups/ecommerce_full_$(date +%Y%m%d).sql
*/

-- STRATEGY 2: Incremental Backup (Every 6 hours)
-- Saves only changes made since the last backup.
-- MySQL binary log incremental (shell command):
/*
  mysqlbinlog --start-datetime="2026-05-18 06:00:00" \
              --stop-datetime="2026-05-18 12:00:00" \
              /var/log/mysql/mysql-bin.log \
              > /backups/incremental_$(date +%Y%m%d_%H).sql
*/

-- STRATEGY 3: Point-in-Time Recovery (PITR) - Continuous
-- WAL segments are streamed in real time to a remote node.
-- Allows restoring the DB to any exact second before a failure.

-- Verify backup integrity (test restore to a staging server):
-- SOURCE /backups/ecommerce_full_20260518.sql;

-- ============================================================
-- CRASH RECOVERY: ARIES PROTOCOL (3 Phases)
-- Executed automatically when the DB server restarts after crash.
--
-- Scenario: Addis Ababa hub crashes during holiday sale peak.
--
-- Phase 1 - ANALYSIS:
--   Scan WAL forward from last checkpoint.
--   Identify: which transactions committed before crash,
--             which were still in progress (incomplete).
--   Result: T1 (Telebirr payment) = COMMITTED
--           T2 (stock decrement)  = INCOMPLETE (in-progress)
--
-- Phase 2 - REDO:
--   Replay ALL changes from COMMITTED transactions.
--   Guarantees committed data is fully written to disk.
--   Result: T1's payment record and order are re-applied.
--
-- Phase 3 - UNDO:
--   Reverse ALL changes from INCOMPLETE transactions.
--   Uses WAL before-images to restore prior state.
--   Result: T2's partial stock decrement is rolled back.
--           Inventory count restored to pre-crash value.
-- ============================================================

-- Simulate the scenario that ARIES would recover:

-- T1 (COMMITTED before crash - will be REDONE by ARIES):
BEGIN;
INSERT INTO Orders (order_id, customer_id, total, status)
VALUES (100, 1, 15000, 'Pending');
INSERT INTO Payments (payment_id, order_id, method, encrypted_reference, status)
VALUES (100, 100, 'Telebirr',
        AES_ENCRYPT('CRASH-TXN-100', 'platform_secret_key_256bit'),
        'Completed');
COMMIT;   -- T1 committed: ARIES Redo phase will ensure this survives

-- T2 (IN-PROGRESS at crash time - will be UNDONE by ARIES):
BEGIN;
UPDATE Inventory
SET stock = stock - 1
WHERE product_id = 1;
-- *** CRASH OCCURS HERE - no COMMIT reached ***
-- ARIES Undo phase will automatically roll this back on restart.

-- ============================================================
-- POST-RECOVERY DATA CONSISTENCY GUARANTEES
-- After ARIES completes all three phases:
-- ============================================================

-- 1. Verify inventory has no negative stock values
SELECT product_id, stock
FROM Inventory
WHERE stock < 0;
-- Expected result: 0 rows (ARIES undo prevents negative stock)

-- 2. Verify every payment has a matching order
SELECT p.payment_id, p.order_id
FROM Payments p
LEFT JOIN Orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;
-- Expected result: 0 rows (no orphaned payment records)

-- 3. Verify every order item references a valid order
SELECT oi.order_item_id, oi.order_id
FROM Order_Items oi
LEFT JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
-- Expected result: 0 rows (no broken order item references)

-- 4. Audit log check: confirm no transactions are in unknown state
SELECT COUNT(*) AS incomplete_count
FROM Audit_Log
WHERE status NOT IN ('SUCCESS', 'FAILED');
-- Expected result: 0
