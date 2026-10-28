-- Experiment 10: Generate 10,000 sales rows and optimize five queries.
-- The PDF refers to an accompanying data-generation script but does not show its full INSERT statement;
-- this file includes a MySQL 8 number-generator INSERT to make the practical runnable.

DROP TABLE IF EXISTS Sales_Records;
CREATE TABLE Sales_Records (
    sale_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_city VARCHAR(50) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    sales_amount DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE NOT NULL,
    sales_status VARCHAR(20) NOT NULL
);

-- Generate 10,000 rows.
INSERT INTO Sales_Records (
    sale_id, customer_name, customer_city, product_name, category,
    sales_amount, quantity, sale_date, sales_status
)
SELECT
    n,
    CONCAT('Customer_', n),
    CASE n % 5
        WHEN 0 THEN 'Delhi'
        WHEN 1 THEN 'Mumbai'
        WHEN 2 THEN 'Lucknow'
        WHEN 3 THEN 'Bengaluru'
        ELSE 'Chennai'
    END,
    CASE n % 5
        WHEN 0 THEN 'Laptop'
        WHEN 1 THEN 'Phone'
        WHEN 2 THEN 'Keyboard'
        WHEN 3 THEN 'Monitor'
        ELSE 'Headphones'
    END,
    CASE n % 4
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Accessories'
        WHEN 2 THEN 'Home'
        ELSE 'Office'
    END,
    100.00 + (n % 5000),
    1 + (n % 10),
    DATE_ADD('2024-01-01', INTERVAL (n % 1095) DAY),
    CASE WHEN n % 4 = 0 THEN 'COMPLETED' ELSE 'PENDING' END
FROM (
    SELECT ones.n + tens.n * 10 + hundreds.n * 100 + thousands.n * 1000 + 1 AS n
    FROM (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) ones
    CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) tens
    CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) hundreds
    CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) thousands
) AS numbers
WHERE n <= 10000;

SELECT COUNT(*) AS total_records FROM Sales_Records;

-- Query 1: function on date column (before optimization)
SELECT COUNT(*) FROM Sales_Records WHERE YEAR(sale_date) = 2025;
EXPLAIN SELECT COUNT(*) FROM Sales_Records WHERE YEAR(sale_date) = 2025;

-- Optimized date range
CREATE INDEX idx_sale_date ON Sales_Records(sale_date);
SELECT COUNT(*) FROM Sales_Records
WHERE sale_date >= '2025-01-01' AND sale_date < '2026-01-01';

-- Query 2: function on city column (before optimization)
SELECT COUNT(*) FROM Sales_Records WHERE LOWER(customer_city) = 'delhi';
EXPLAIN SELECT COUNT(*) FROM Sales_Records WHERE LOWER(customer_city) = 'delhi';

-- Optimized city filter
CREATE INDEX idx_customer_city ON Sales_Records(customer_city);
SELECT COUNT(*) FROM Sales_Records WHERE customer_city = 'Delhi';

-- Query 3: two-column filter
SELECT COUNT(*) FROM Sales_Records
WHERE category = 'Electronics' AND sales_status = 'COMPLETED';
EXPLAIN SELECT COUNT(*) FROM Sales_Records
WHERE category = 'Electronics' AND sales_status = 'COMPLETED';

CREATE INDEX idx_category_status ON Sales_Records(category, sales_status);

-- Query 4: filter and ordering
SELECT sale_id, customer_name, sales_amount, sale_date
FROM Sales_Records
WHERE customer_city = 'Mumbai'
ORDER BY sale_date DESC
LIMIT 20;
EXPLAIN
SELECT sale_id, customer_name, sales_amount, sale_date
FROM Sales_Records
WHERE customer_city = 'Mumbai'
ORDER BY sale_date DESC
LIMIT 20;

CREATE INDEX idx_city_date ON Sales_Records(customer_city, sale_date);

-- Query 5: correlated subquery
SELECT s.sale_id, s.product_name, s.category, s.sales_amount
FROM Sales_Records AS s
WHERE s.sales_amount > (
    SELECT AVG(s2.sales_amount)
    FROM Sales_Records AS s2
    WHERE s2.category = s.category
);

CREATE INDEX idx_category_amount ON Sales_Records(category, sales_amount);

-- Rewritten query: calculate each category average once and join it.
SELECT s.sale_id, s.product_name, s.category, s.sales_amount
FROM Sales_Records AS s
JOIN (
    SELECT category, AVG(sales_amount) AS avg_amount
    FROM Sales_Records
    GROUP BY category
) AS a ON s.category = a.category
WHERE s.sales_amount > a.avg_amount;

-- Example timing pattern; repeat around each query to compare measurements.
SET @start_time = NOW(6);
SELECT COUNT(*) FROM Sales_Records WHERE YEAR(sale_date) = 2025;
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, NOW(6)) AS execution_time_microseconds;

-- Inspect indexes and verify row count.
SHOW INDEX FROM Sales_Records;
SELECT COUNT(*) AS total_records FROM Sales_Records;
