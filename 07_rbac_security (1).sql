-- ============================================================
-- FILE: 07_rbac_security.sql
-- SECTION: Security - Role-Based Access Control (RBAC)
-- CONTRIBUTOR: ADANE DIGA | ID: MTUUR/8415/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- ============================================================
-- ROLE-BASED ACCESS CONTROL (RBAC)
-- Instead of granting permissions to individual users,
-- permissions are assigned to ROLES, and roles are assigned
-- to users. This makes permission management much easier.
--
-- Three roles in this system:
--   Admin    → Full access to all tables and settings
--   Seller   → Can manage products and inventory; read orders
--   Customer → Can browse products, place orders, make payments
-- ============================================================

-- ============================================================
-- STEP 1: Create the three roles
-- ============================================================

CREATE ROLE admin;
CREATE ROLE seller;
CREATE ROLE customer;

-- ============================================================
-- STEP 2: Grant ADMIN full privileges on all tables
-- Admin can read, write, update, delete anything in the system.
-- ============================================================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

-- ============================================================
-- STEP 3: Grant SELLER product and inventory management
-- Sellers can add/update products and stock but cannot
-- modify customer data or payment records.
-- ============================================================

GRANT ALL PRIVILEGES ON Products   TO seller;
GRANT ALL PRIVILEGES ON Inventory  TO seller;
GRANT SELECT         ON Orders     TO seller;
GRANT SELECT         ON Order_Items TO seller;
GRANT SELECT         ON Categories TO seller;
-- Sellers CANNOT access Customers, Payments, or Audit_Log

-- ============================================================
-- STEP 4: Grant CUSTOMER limited access
-- Customers can browse products and manage their own orders.
-- They cannot access other customers' data or audit logs.
-- ============================================================

GRANT SELECT         ON Products     TO customer;
GRANT SELECT         ON Categories   TO customer;
GRANT SELECT         ON Inventory    TO customer;
GRANT SELECT, INSERT ON Orders       TO customer;
GRANT SELECT, INSERT ON Order_Items  TO customer;
GRANT SELECT, INSERT ON Payments     TO customer;
-- Customers CANNOT access Audit_Log or other users' accounts

-- ============================================================
-- STEP 5: Assign roles to actual database users
-- ============================================================

GRANT admin    TO db_admin_user;
GRANT seller   TO seller_user;
GRANT customer TO customer_user;

-- ============================================================
-- STEP 6: Revoke access example (if a seller leaves)
-- ============================================================

-- REVOKE ALL PRIVILEGES ON Products  FROM seller_user;
-- REVOKE ALL PRIVILEGES ON Inventory FROM seller_user;
-- DROP ROLE seller;  -- Only after revoking from all users

-- ============================================================
-- STEP 7: Verify role grants (PostgreSQL)
-- ============================================================

-- Show all roles
SELECT rolname FROM pg_roles;

-- Show which privileges are granted on a specific table
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'Products';

-- ============================================================
-- MYSQL EQUIVALENT (if using MySQL instead of PostgreSQL)
-- ============================================================

-- CREATE USER 'admin_user'@'localhost'    IDENTIFIED BY 'strong_password_1';
-- CREATE USER 'seller_user'@'localhost'   IDENTIFIED BY 'strong_password_2';
-- CREATE USER 'customer_user'@'localhost' IDENTIFIED BY 'strong_password_3';

-- GRANT ALL PRIVILEGES ON ecommerce.* TO 'admin_user'@'localhost';

-- GRANT SELECT, INSERT, UPDATE, DELETE ON ecommerce.Products   TO 'seller_user'@'localhost';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ecommerce.Inventory  TO 'seller_user'@'localhost';
-- GRANT SELECT                         ON ecommerce.Orders     TO 'seller_user'@'localhost';

-- GRANT SELECT                         ON ecommerce.Products    TO 'customer_user'@'localhost';
-- GRANT SELECT                         ON ecommerce.Categories  TO 'customer_user'@'localhost';
-- GRANT SELECT, INSERT                 ON ecommerce.Orders      TO 'customer_user'@'localhost';
-- GRANT SELECT, INSERT                 ON ecommerce.Order_Items TO 'customer_user'@'localhost';
-- GRANT SELECT, INSERT                 ON ecommerce.Payments    TO 'customer_user'@'localhost';

-- FLUSH PRIVILEGES;
