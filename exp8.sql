-- Experiment 8: Banking transactions, SAVEPOINT, isolation, and concurrency.
-- Run setup once. For two-session tests, open two separate database sessions and follow the comments.
-- Some platforms do not allow CREATE DATABASE; if so, select your provided database and omit CREATE DATABASE/USE.

CREATE DATABASE IF NOT EXISTS LabPracticalDB;
USE LabPracticalDB;

DROP TABLE IF EXISTS Bank_Account;
CREATE TABLE Bank_Account (
    account_id INT PRIMARY KEY,
    account_holder VARCHAR(100) NOT NULL,
    balance DECIMAL(12,2) NOT NULL
);

INSERT INTO Bank_Account (account_id, account_holder, balance) VALUES
(101, 'Aarav Sharma', 50000.00),
(102, 'Vihaan Singh', 30000.00),
(103, 'Ananya Gupta', 25000.00),
(104, 'Advik Desai', 40000.00);

SELECT * FROM Bank_Account;

-- Transaction 1: successful transfer; both updates are committed together.
START TRANSACTION;
UPDATE Bank_Account SET balance = balance - 5000 WHERE account_id = 101;
UPDATE Bank_Account SET balance = balance + 5000 WHERE account_id = 102;
COMMIT;
SELECT * FROM Bank_Account WHERE account_id IN (101, 102);

-- Transaction 2: rollback cancels both updates.
START TRANSACTION;
UPDATE Bank_Account SET balance = balance - 3000 WHERE account_id = 102;
UPDATE Bank_Account SET balance = balance + 3000 WHERE account_id = 103;
ROLLBACK;
SELECT * FROM Bank_Account WHERE account_id IN (102, 103);

-- SAVEPOINT: keep the first transfer, undo the second.
START TRANSACTION;
UPDATE Bank_Account SET balance = balance - 2000 WHERE account_id = 101;
UPDATE Bank_Account SET balance = balance + 2000 WHERE account_id = 102;
SAVEPOINT after_first_transfer;
UPDATE Bank_Account SET balance = balance - 4000 WHERE account_id = 102;
UPDATE Bank_Account SET balance = balance + 4000 WHERE account_id = 103;
ROLLBACK TO SAVEPOINT after_first_transfer;
COMMIT;
SELECT * FROM Bank_Account;

-- Partial failure example. Account 9999 does not exist, so the second UPDATE changes zero rows.
START TRANSACTION;
UPDATE Bank_Account SET balance = balance - 1000 WHERE account_id = 101;
UPDATE Bank_Account SET balance = balance + 1000 WHERE account_id = 104;
SAVEPOINT transfer_1;
UPDATE Bank_Account SET balance = balance - 500 WHERE account_id = 9999;
ROLLBACK TO SAVEPOINT transfer_1;
COMMIT;
SELECT * FROM Bank_Account WHERE account_id IN (101, 104);

-- Check/set isolation level for the current session. Run one SET statement at a time if needed.
SELECT @@transaction_isolation;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Alternatives:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- TWO-SESSION TEST A: dirty read (Session A and Session B)
-- SESSION A:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- START TRANSACTION;
-- UPDATE Bank_Account SET balance = balance + 10000 WHERE account_id = 101;
-- Do not commit yet.
-- SESSION B:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- START TRANSACTION;
-- SELECT balance FROM Bank_Account WHERE account_id = 101;
-- SESSION B: ROLLBACK;
-- SESSION A: ROLLBACK;
-- Observation: Session B may see Session A's uncommitted value under READ UNCOMMITTED.

-- TWO-SESSION TEST B: non-repeatable read (READ COMMITTED)
-- SESSION A:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
-- SELECT balance FROM Bank_Account WHERE account_id = 102;
-- SESSION B:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
-- UPDATE Bank_Account SET balance = balance + 5000 WHERE account_id = 102;
-- COMMIT;
-- SESSION A: run the same SELECT again, then COMMIT.
-- Observation: Session A may see the newly committed value on the second read.

-- TWO-SESSION TEST C: repeatable read
-- SESSION A:
-- SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- START TRANSACTION;
-- SELECT balance FROM Bank_Account WHERE account_id = 103;
-- SESSION B:
-- START TRANSACTION;
-- UPDATE Bank_Account SET balance = balance + 2000 WHERE account_id = 103;
-- COMMIT;
-- SESSION A: run the same SELECT again, then COMMIT.
-- Observation: ordinary consistent reads usually keep the same snapshot in InnoDB REPEATABLE READ.

-- TWO-SESSION TEST D: row-lock blocking
-- SESSION A:
-- START TRANSACTION;
-- SELECT * FROM Bank_Account WHERE account_id = 104 FOR UPDATE;
-- SESSION B:
-- START TRANSACTION;
-- UPDATE Bank_Account SET balance = balance - 1000 WHERE account_id = 104;
-- This UPDATE waits until Session A commits.
-- SESSION A: COMMIT;
-- SESSION B: COMMIT;

-- Stored procedure with validation and rollback handling.
DROP PROCEDURE IF EXISTS transfer_money;
DELIMITER //
CREATE PROCEDURE transfer_money(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(12,2)
)
BEGIN
    DECLARE v_from_exists INT DEFAULT 0;
    DECLARE v_to_exists INT DEFAULT 0;
    DECLARE v_balance DECIMAL(12,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Transaction Failed: Changes rolled back.' AS Status_Message;
    END;

    START TRANSACTION;

    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transfer amount must be positive';
    END IF;

    SELECT COUNT(*) INTO v_from_exists
    FROM Bank_Account WHERE account_id = p_from_account;
    IF v_from_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Source account does not exist';
    END IF;

    SELECT COUNT(*) INTO v_to_exists
    FROM Bank_Account WHERE account_id = p_to_account;
    IF v_to_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Destination account does not exist';
    END IF;

    SELECT balance INTO v_balance
    FROM Bank_Account
    WHERE account_id = p_from_account
    FOR UPDATE;

    IF v_balance < p_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;

    SAVEPOINT before_transfer;
    UPDATE Bank_Account SET balance = balance - p_amount WHERE account_id = p_from_account;
    UPDATE Bank_Account SET balance = balance + p_amount WHERE account_id = p_to_account;
    COMMIT;

    SELECT CONCAT('Success: ', p_amount, ' transferred from ', p_from_account,
                  ' to ', p_to_account) AS Status_Message;
END //
DELIMITER ;

-- Test procedure calls separately:
CALL transfer_money(101, 102, 2000);
-- CALL transfer_money(999, 102, 2000);       -- invalid source account
-- CALL transfer_money(101, 999, 2000);       -- invalid destination account
-- CALL transfer_money(101, 102, -500);       -- invalid amount
-- CALL transfer_money(103, 101, 999999);     -- insufficient balance

SELECT * FROM Bank_Account ORDER BY account_id;
