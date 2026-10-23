# DBMS Lab: Experiments 3–6

This repository contains the lab record PDF and separate MySQL 8 scripts for Experiments 3, 4, 5, and 6. The experiment scripts share one database and build on one another, so run them in order.

## Files

| File | Description |
|---|---|
| [`exp-3to6 dbms.pdf`](exp-3to6%20dbms.pdf) | Original lab record for Experiments 3–6, including aims, code, and output pages |
| [`sql/experiment3.sql`](sql/experiment3.sql) | Creates and seeds departments, employees, projects, and work assignments; demonstrates basic queries |
| [`sql/experiment4.sql`](sql/experiment4.sql) | Adds manager relationships; demonstrates joins, subqueries, simulated set operations, and `EXPLAIN` |
| [`sql/experiment5.sql`](sql/experiment5.sql) | Creates views, demonstrates view updatability, and runs recursive reporting-chain queries |
| [`sql/experiment6.sql`](sql/experiment6.sql) | Adds salary validation and audit triggers plus the `transfer_employee` procedure |

## Experiment overview

### Experiment 3 — Employee, Department, and Project schema

Creates five departments, 30 employees, eight projects, and the `Works_On` assignment table. Demonstrates selection, projection, aggregate functions, `GROUP BY`, `HAVING`, `CASE`, and `ORDER BY`.

### Experiment 4 — Joins, subqueries, and query plans

Adds a manager column and uses inner, left, self, and three-table joins; correlated subqueries; `EXISTS`; simulated `INTERSECT` and `EXCEPT`; and `EXPLAIN` before and after adding an index.

### Experiment 5 — Views and recursive CTEs

Creates department-salary and employee-hierarchy views, tests a filtered updatable view with `WITH CHECK OPTION`, checks view metadata, and uses recursive CTEs to show employee chains downward, upward, and by level.

### Experiment 6 — Procedure, validation, and audit triggers

Creates triggers that limit salaries to 10,000–200,000, prevent salary reductions greater than 50 percent, and record employee inserts, updates, and deletes in `audit_log`. The `transfer_employee` procedure checks IDs, rejects employees with direct reports, and updates department assignments transactionally.

## Run the scripts

Install MySQL 8 and run these commands from the repository root:

```sh
mysql < sql/experiment3.sql
mysql < sql/experiment4.sql
mysql < sql/experiment5.sql
mysql < sql/experiment6.sql
```

All scripts use the `dbms_lab` database. Experiment 3 creates the base tables and sample rows; Experiments 4–6 depend on that schema. Run each script once in order. The scripts include expected-error statements as comments; uncomment and run those individually if you want to observe validation failures. To start over, drop the `dbms_lab` database and run the sequence again.

## Notes

- The PDF remains the original source record. The SQL files normalize typographic quotation marks and delimiter formatting so the code can be executed in MySQL 8.
- Experiment 5 intentionally comments out updates that are expected to fail due to view restrictions.
- Experiment 6 includes a valid transfer and salary update as examples. Other validation cases remain commented to prevent an expected error from stopping the script.
