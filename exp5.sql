-- Experiment 5: Views, updatability, and recursive CTE reporting chains
-- Run experiment3.sql and experiment4.sql first.
USE dbms_lab;

-- Reparent department leaders under employee 107, as in the lab record.
UPDATE Employee SET manager_id = 107 WHERE emp_id IN (102, 113, 118, 129);

CREATE OR REPLACE VIEW dept_salary_summary AS
SELECT d.dept_id, d.dept_name,
       COUNT(e.emp_id) AS num_employees,
       SUM(e.salary) AS total_salary,
       ROUND(AVG(e.salary), 2) AS avg_salary,
       MAX(e.salary) AS max_salary,
       MIN(e.salary) AS min_salary
FROM Department d
JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_salary_summary;

CREATE OR REPLACE VIEW employee_hierarchy AS
SELECT e.emp_id, e.emp_name, d.dept_name, m.emp_name AS manager_name
FROM Employee e
JOIN Department d ON e.dept_id = d.dept_id
LEFT JOIN Employee m ON e.manager_id = m.emp_id;

SELECT * FROM employee_hierarchy ORDER BY emp_id;

-- A simple filtered view with a check option is updatable.
CREATE OR REPLACE VIEW emp_it_view AS
SELECT emp_id, emp_name, salary, dept_id
FROM Employee
WHERE dept_id = 2
WITH CHECK OPTION;

UPDATE emp_it_view SET salary = 61000 WHERE emp_id = 111;
SELECT emp_id, emp_name, salary FROM Employee WHERE emp_id = 111;
UPDATE emp_it_view SET salary = 60000 WHERE emp_id = 111;
INSERT INTO emp_it_view VALUES (131, 'Test User', 50000, 2);
SELECT * FROM Employee WHERE emp_id = 131;
DELETE FROM emp_it_view WHERE emp_id = 131;

-- Expected errors; uncomment one at a time to observe view restrictions.
-- This fails the WITH CHECK OPTION because dept_id would leave the view filter:
-- UPDATE emp_it_view SET dept_id = 3 WHERE emp_id = 111;
-- Aggregate/grouped views are not updatable:
-- UPDATE dept_salary_summary SET total_salary = 0 WHERE dept_id = 1;

SELECT table_name, is_updatable
FROM information_schema.views
WHERE table_schema = DATABASE();

-- Downward reporting paths from top-level employees
WITH RECURSIVE chain AS (
    SELECT emp_id, emp_name, manager_id, 1 AS level,
           CAST(emp_name AS CHAR(300)) AS chain_path
    FROM Employee
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, c.level + 1,
           CONCAT(c.chain_path, ' -> ', e.emp_name)
    FROM Employee e
    JOIN chain c ON e.manager_id = c.emp_id
)
SELECT emp_id, emp_name, level, chain_path
FROM chain
ORDER BY chain_path;

-- Upward chain from employee 123 to the top-level manager
WITH RECURSIVE up_chain AS (
    SELECT emp_id, emp_name, manager_id, 1 AS step
    FROM Employee WHERE emp_id = 123
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, u.step + 1
    FROM Employee e
    JOIN up_chain u ON e.emp_id = u.manager_id
)
SELECT step, emp_id, emp_name FROM up_chain;

-- Count employees at each level
WITH RECURSIVE chain AS (
    SELECT emp_id, 1 AS level FROM Employee WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, c.level + 1
    FROM Employee e
    JOIN chain c ON e.manager_id = c.emp_id
)
SELECT level, COUNT(*) AS employees
FROM chain
GROUP BY level;
