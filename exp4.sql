-- Experiment 4: Joins, subqueries, set-operation patterns, and EXPLAIN
-- Run experiment3.sql first. This adds manager_id to Employee and an index.
USE dbms_lab;

ALTER TABLE Employee ADD manager_id INT NULL;
ALTER TABLE Employee
    ADD CONSTRAINT fk_employee_manager FOREIGN KEY (manager_id) REFERENCES Employee(emp_id);

UPDATE Employee SET manager_id = 102 WHERE dept_id = 1 AND emp_id <> 102;
UPDATE Employee SET manager_id = 107 WHERE dept_id = 2 AND emp_id <> 107;
UPDATE Employee SET manager_id = 113 WHERE dept_id = 3 AND emp_id <> 113;
UPDATE Employee SET manager_id = 118 WHERE dept_id = 4 AND emp_id <> 118;
UPDATE Employee SET manager_id = 129 WHERE dept_id = 5 AND emp_id <> 129;

-- INNER JOIN: employee and department details
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- LEFT JOIN: employees without project assignments
SELECT e.emp_id, e.emp_name, w.proj_id
FROM Employee e
LEFT JOIN Works_On w ON e.emp_id = w.emp_id
WHERE w.proj_id IS NULL;

-- Self-join: employees and their managers
SELECT e.emp_name AS employee, m.emp_name AS manager
FROM Employee e
LEFT JOIN Employee m ON e.manager_id = m.emp_id
ORDER BY m.emp_name, e.emp_name;

-- Three-table join: employee, work assignment, project
SELECT e.emp_name, p.proj_name, p.budget, w.hours
FROM Employee e
JOIN Works_On w ON e.emp_id = w.emp_id
JOIN Project p ON w.proj_id = p.proj_id
WHERE w.hours > 150
ORDER BY w.hours DESC;

-- Correlated subquery: salary greater than department average
SELECT e.emp_name, e.salary, e.dept_id
FROM Employee e
WHERE e.salary > (
    SELECT AVG(e2.salary) FROM Employee e2 WHERE e2.dept_id = e.dept_id
)
ORDER BY e.dept_id, e.salary DESC;

-- EXISTS: departments with a project budget of at least 600,000
SELECT d.dept_name
FROM Department d
WHERE EXISTS (
    SELECT 1 FROM Project p
    WHERE p.dept_id = d.dept_id AND p.budget >= 600000
);

-- Employees not assigned to a project
SELECT e.emp_name
FROM Employee e
WHERE NOT EXISTS (SELECT 1 FROM Works_On w WHERE w.emp_id = e.emp_id);

-- Simulated INTERSECT: employees on both projects 1 and 2
SELECT DISTINCT e.emp_id, e.emp_name
FROM Employee e
JOIN Works_On w ON e.emp_id = w.emp_id
WHERE w.proj_id = 1
  AND e.emp_id IN (SELECT emp_id FROM Works_On WHERE proj_id = 2);

-- Simulated EXCEPT: employees on project 1 but not project 2
SELECT DISTINCT e.emp_id, e.emp_name
FROM Employee e
JOIN Works_On w ON e.emp_id = w.emp_id
WHERE w.proj_id = 1
  AND e.emp_id NOT IN (SELECT emp_id FROM Works_On WHERE proj_id = 2);

-- Compare execution plans
EXPLAIN SELECT e.emp_name, e.salary
FROM Employee e
WHERE e.salary > (
    SELECT AVG(e2.salary) FROM Employee e2 WHERE e2.dept_id = e.dept_id
);

EXPLAIN SELECT e.emp_name, e.salary
FROM Employee e
JOIN (SELECT dept_id, AVG(salary) AS avg_sal FROM Employee GROUP BY dept_id) a
  ON e.dept_id = a.dept_id
WHERE e.salary > a.avg_sal;

EXPLAIN SELECT * FROM Employee WHERE dept_id = 2;
CREATE INDEX idx_emp_dept ON Employee(dept_id);
EXPLAIN SELECT * FROM Employee WHERE dept_id = 2;
