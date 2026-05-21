-- ============================================================
-- FILE: 08_encryption.sql
-- SECTION: Security - Encryption & Password Hashing
-- CONTRIBUTOR: BELAY TESHOME | ID: MTUUR/8606/17
-- PROJECT: E-Commerce Platform System
-- COURSE: Advanced Databases | ITce 2024 | Group 2 Section A
-- ============================================================

-- ============================================================
-- AES-256 ENCRYPTION
-- Used for sensitive data fields: payment references, phone numbers.
-- AES encryption is REVERSIBLE (unlike hashing) — authorized
-- admins can decrypt to retrieve the original value.
-- ============================================================

-- Store encrypted Telebirr payment reference
INSERT INTO Payments (payment_id, order_id, method, encrypted_reference, status)
VALUES (
    10,
    1,
    'Telebirr',
    AES_ENCRYPT('09-1234-5678-transaction-ref', 'platform_secret_key_256bit'),
    'Completed'
);

-- Decrypt and read the payment reference (admin only)
SELECT
    payment_id,
    order_id,
    method,
    CAST(AES_DECRYPT(encrypted_reference, 'platform_secret_key_256bit') AS CHAR) AS transaction_ref,
    status
FROM Payments
WHERE payment_id = 10;

-- ============================================================
-- ENCRYPTING CUSTOMER PHONE NUMBERS
-- The phone column is VARBINARY(255) to store encrypted binary.
-- The original phone number is NEVER saved as plain text.
-- ============================================================

-- Insert customer with encrypted phone
INSERT INTO Customers (customer_id, name, email, phone, city)
VALUES (
    10,
    'Biniyam',
    'biniyam@example.com',
    AES_ENCRYPT('0912345678', 'platform_secret_key_256bit'),
    'Addis Ababa'
);

-- Decrypt phone number for admin retrieval
SELECT
    customer_id,
    name,
    email,
    CAST(AES_DECRYPT(phone, 'platform_secret_key_256bit') AS CHAR) AS phone_number,
    city
FROM Customers
WHERE customer_id = 10;

-- ============================================================
-- PASSWORD HASHING
-- Unlike encryption, hashing is ONE-WAY — the original
-- password can NEVER be recovered from the hash.
-- Even if the database is breached, passwords stay safe.
-- SHA2 with 256-bit is used here (bcrypt recommended in production).
-- ============================================================

-- Store a hashed password (never store plain text passwords)
INSERT INTO User_Accounts (account_id, username, password_hash, customer_id)
VALUES (
    10,
    'biniyam_aa',
    SHA2('MySecurePassword123!', 256),  -- One-way hash stored
    10
);

-- Verify login: hash the input and compare (never compare plain text)
SELECT
    account_id,
    username,
    CASE
        WHEN password_hash = SHA2('MySecurePassword123!', 256)
        THEN 'LOGIN SUCCESS'
        ELSE 'WRONG PASSWORD'
    END AS login_result
FROM User_Accounts
WHERE username = 'biniyam_aa';

-- ============================================================
-- ACCOUNT LOCKOUT POLICY
-- Locks the account for 30 minutes after 5 consecutive
-- failed login attempts (brute-force protection).
-- ============================================================

DELIMITER $$

CREATE TRIGGER after_failed_login
AFTER UPDATE ON User_Accounts
FOR EACH ROW
BEGIN
    IF NEW.failed_attempts >= 5 THEN
        UPDATE User_Accounts
        SET locked_until = DATE_ADD(NOW(), INTERVAL 30 MINUTE)
        WHERE account_id = NEW.account_id;
    END IF;
END$$

DELIMITER ;

-- Check if an account is currently locked before allowing login
SELECT
    account_id,
    username,
    failed_attempts,
    locked_until,
    CASE
        WHEN locked_until > NOW() THEN 'LOCKED - Try again later'
        ELSE 'ACTIVE'
    END AS account_status
FROM User_Accounts
WHERE username = 'biniyam_aa';

-- Reset failed attempts after a successful login
UPDATE User_Accounts
SET failed_attempts = 0,
    last_login = NOW()
WHERE username = 'biniyam_aa';
