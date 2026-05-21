-- ============================================================
-- FILE: 04_optimized_queries.sql
-- SECTION: Optimized SQL Queries & Index Strategies
-- CONTRIBUTOR: BEWKET ABIE | ID: MTUUR/7822/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- ============================================================
-- INDEXES (must be created before running queries)
-- Indexes allow the database engine to skip full table scans.
-- ============================================================

-- Optimizes Query 1: product search by category and price range
CREATE INDEX idx_products_search
    ON Products (category_id, price);

-- Optimizes Query 3: customer order history sorted by date
CREATE INDEX idx_orders_customer
    ON Orders (customer_id, created_at DESC);

-- Optimizes Query 4: revenue report filtered by status and date
CREATE INDEX idx_orders_revenue
    ON Orders (status, created_at);

-- Optimizes Query 2: top-selling products join
CREATE INDEX idx_order_items_product
    ON Order_Items (product_id);

-- ============================================================
-- QUERY 1: Product Search (by category, price range, keyword)
-- Uses index: idx_products_search
-- Technique: Index Range Scan (avoids full table scan)
-- ============================================================

SELECT
    p.product_id,
    p.name,
    p.price,
    i.stock
FROM Products p
JOIN Inventory i ON p.product_id = i.product_id
JOIN Categories c ON p.category_id = c.category_id
WHERE c.category_name = 'Electronics'
  AND p.price BETWEEN 5000 AND 20000
  AND p.name LIKE '%Laptop%'
ORDER BY p.price ASC;

-- View the execution plan to confirm index usage:
EXPLAIN SELECT
    p.product_id,
    p.name,
    p.price,
    i.stock
FROM Products p
JOIN Inventory i ON p.product_id = i.product_id
JOIN Categories c ON p.category_id = c.category_id
WHERE c.category_name = 'Electronics'
  AND p.price BETWEEN 5000 AND 20000
  AND p.name LIKE '%Laptop%'
ORDER BY p.price ASC;

-- ============================================================
-- QUERY 2: Top-Selling Products
-- Uses index: idx_order_items_product
-- Technique: Hash Join (in-memory key matching, faster than Nested Loop)
-- ============================================================

SELECT
    p.product_id,
    p.name,
    SUM(oi.quantity) AS total_sold
FROM Products p
JOIN Order_Items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name
ORDER BY total_sold DESC
LIMIT 5;

-- ============================================================
-- QUERY 3: Customer Order History
-- Uses index: idx_orders_customer
-- Returns all orders for a specific customer with payment method.
-- ============================================================

SELECT
    o.order_id,
    o.total,
    o.status,
    o.created_at,
    p.method AS payment_method
FROM Orders o
LEFT JOIN Payments p ON o.order_id = p.order_id
WHERE o.customer_id = 1
ORDER BY o.created_at DESC;

-- ============================================================
-- QUERY 4: Daily/Monthly Revenue Report
-- Uses index: idx_orders_revenue
-- IMPORTANT: Uses explicit timestamp range (NOT DATE() function)
-- because wrapping in DATE() makes query non-sargable and
-- forces a full table scan even with an index present.
-- ============================================================

SELECT
    CAST(created_at AS DATE) AS order_date,
    SUM(total) AS daily_revenue
FROM Orders
WHERE status = 'Delivered'
  AND created_at >= '2026-05-01 00:00:00'
  AND created_at <= '2026-05-31 23:59:59'
GROUP BY CAST(created_at AS DATE)
ORDER BY order_date DESC;

-- ============================================================
-- QUERY 5: Low-Stock Product Alerts
-- Quickly identifies products needing restocking.
-- ============================================================

SELECT
    p.product_id,
    p.name,
    i.stock
FROM Products p
JOIN Inventory i ON p.product_id = i.product_id
WHERE i.stock < 5
ORDER BY i.stock ASC;
