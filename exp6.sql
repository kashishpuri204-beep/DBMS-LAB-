-- Experiment 6: Stored procedure validation, salary triggers, and audit logging
-- Run experiment3.sql and experiment4.sql first (manager_id is used for validation).
USE dbms_lab;

CREATE TABLE IF NOT EXISTS audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT,
    action_type VARCHAR(20),
    old_value VARCHAR(100),
    new_value VARCHAR(100),
    changed_on DATETIME DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS trg_salary_check_insert;
DROP TRIGGER IF EXISTS trg_salary_check_update;
DROP TRIGGER IF EXISTS trg_audit_insert;
DROP TRIGGER IF EXISTS trg_audit_update;
DROP TRIGGER IF EXISTS trg_audit_delete;
DROP PROCEDURE IF EXISTS transfer_employee;

DELIMITER $$

CREATE TRIGGER trg_salary_check_insert
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary < 10000 OR NEW.salary > 200000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid salary: must be between 10000 and 200000';
    END IF;
END$$

CREATE TRIGGER trg_salary_check_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary < 10000 OR NEW.salary > 200000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid salary: must be between 10000 and 200000';
    END IF;
    IF NEW.salary < OLD.salary * 0.5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Salary cannot be reduced by more than 50 percent';
    END IF;
END$$

CREATE TRIGGER trg_audit_insert
AFTER INSERT ON Employee
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (emp_id, action_type, old_value, new_value)
    VALUES (NEW.emp_id, 'INSERT', NULL,
            CONCAT(NEW.emp_name, ' | dept ', NEW.dept_id));
END$$

CREATE TRIGGER trg_audit_update
AFTER UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NOT (OLD.salary <=> NEW.salary) THEN
        INSERT INTO audit_log (emp_id, action_type, old_value, new_value)
        VALUES (NEW.emp_id, 'SALARY_CHANGE', OLD.salary, NEW.salary);
    END IF;
    IF NOT (OLD.dept_id <=> NEW.dept_id) THEN
