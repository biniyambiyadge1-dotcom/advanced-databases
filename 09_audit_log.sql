CREATE TABLE Audit_Log (
    log_id     INT PRIMARY KEY AUTO_INCREMENT,
    user_id    INT NOT NULL,
    username   VARCHAR(100),
    action     VARCHAR(100) NOT NULL,
    table_name VARCHAR(50),
    record_id  INT,
    old_value  TEXT,           -- Value before the change (UPDATE/DELETE)
    new_value  TEXT,           -- Value after the change  (INSERT/UPDATE)
    ip_address VARCHAR(45),    -- User's IP address
    status     ENUM('SUCCESS', 'FAILED') DEFAULT 'SUCCESS',
    timestamp  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User_Accounts(account_id)
);
DELIMITER $$

CREATE PROCEDURE log_login_attempt(
    IN p_username   VARCHAR(100),
    IN p_ip_address VARCHAR(45),
    IN p_success    BOOLEAN
)
BEGIN
    DECLARE v_user_id INT DEFAULT NULL;
    DECLARE v_status  VARCHAR(10);

    -- Get the user's account ID
    SELECT account_id INTO v_user_id
    FROM User_Accounts
    WHERE username = p_username;

    SET v_status = IF(p_success, 'SUCCESS', 'FAILED');
    INSERT INTO Audit_Log (user_id, username, action, ip_address, status)
    VALUES (v_user_id, p_username, 'LOGIN_ATTEMPT', p_ip_address, v_status);
    IF NOT p_success THEN
        UPDATE User_Accounts
        SET failed_attempts = failed_attempts + 1
        WHERE username = p_username;
    ELSE
        UPDATE User_Accounts
        SET failed_attempts = 0,
            last_login = NOW()
        WHERE username = p_username;
    END IF;
END$$

DELIMITER ;
CALL log_login_attempt('biniyam_aa', '192.168.1.10', TRUE);   
CALL log_login_attempt('baye_adama', '10.0.0.5',    FALSE);   
DELIMITER $$
CREATE TRIGGER after_order_placed
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (user_id, username, action, table_name, record_id, new_value, status)
    SELECT
        ua.account_id,
        ua.username,
        'ORDER_PLACED',
        'Orders',
        NEW.order_id,
        CONCAT('Total: ', NEW.total, ', Status: ', NEW.status),
        'SUCCESS'
    FROM User_Accounts ua
    WHERE ua.customer_id = NEW.customer_id;
END$$

DELIMITER ;
SELECT
    username,
    ip_address,
    COUNT(*) AS failed_count
FROM Audit_Log
WHERE action    = 'LOGIN_ATTEMPT'
  AND status    = 'FAILED'
  AND timestamp >= NOW() - INTERVAL 1 HOUR
GROUP BY username, ip_address
HAVING COUNT(*) > 3
ORDER BY failed_count DESC;
SELECT
    al.user_id,
    al.username,
    COUNT(*) AS order_count
FROM Audit_Log al
WHERE al.action    = 'ORDER_PLACED'
  AND al.timestamp >= NOW() - INTERVAL 1 HOUR
GROUP BY al.user_id, al.username
HAVING COUNT(*) > 5
ORDER BY order_count DESC;
SELECT
    log_id,
    action,
    table_name,
    record_id,
    old_value,
    new_value,
    ip_address,
    status,
    timestamp
FROM Audit_Log
WHERE username = 'biniyam_aa'
ORDER BY timestamp DESC;
