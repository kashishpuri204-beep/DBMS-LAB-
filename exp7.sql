-- Experiment 7: Normalize a Sales table from 1NF/UNF to 3NF and BCNF.
-- Based on the supplied PDF. Run in a fresh schema or remove old tables first.
-- Note: The PDF's sample decomposition has assumptions about discount_code -> product_id.
-- Review that functional dependency with your instructor before treating the BCNF result as definitive.

DROP TABLE IF EXISTS OrderItems_BCNF;
DROP TABLE IF EXISTS Discounts_BCNF;
DROP TABLE IF EXISTS Orders_3NF;
DROP TABLE IF EXISTS Customers_3NF;
DROP TABLE IF EXISTS OrderDetails_2NF;
DROP TABLE IF EXISTS Products_2NF;
DROP TABLE IF EXISTS Orders_2NF;
DROP TABLE IF EXISTS Sales_1NF;

CREATE TABLE Sales_1NF (
    order_id INT,
    product_id INT,
    customer_id INT,
    customer_name VARCHAR(50),
    product_name VARCHAR(50),
    quantity INT,
    discount_code VARCHAR(20),
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO Sales_1NF VALUES
(1, 101, 501, 'Aarav Sharma', 'Laptop', 1, 'LAP10'),
(1, 102, 501, 'Aarav Sharma', 'Mouse', 2, 'MOU20'),
(2, 101, 502, 'Diya Kumar', 'Laptop', 1, 'LAP10'),
(3, 103, 501, 'Aarav Sharma', 'Keyboard', 1, 'KEY50');

-- 2NF decomposition
CREATE TABLE Orders_2NF (
    order_id INT PRIMARY KEY,
    customer_id INT,
    customer_name VARCHAR(50)
);
INSERT INTO Orders_2NF (order_id, customer_id, customer_name)
SELECT DISTINCT order_id, customer_id, customer_name FROM Sales_1NF;

CREATE TABLE Products_2NF (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50)
);
INSERT INTO Products_2NF (product_id, product_name)
SELECT DISTINCT product_id, product_name FROM Sales_1NF;

CREATE TABLE OrderDetails_2NF (
    order_id INT,
    product_id INT,
    quantity INT,
    discount_code VARCHAR(20),
    PRIMARY KEY (order_id, product_id)
);
INSERT INTO OrderDetails_2NF (order_id, product_id, quantity, discount_code)
SELECT order_id, product_id, quantity, discount_code FROM Sales_1NF;

-- 3NF decomposition
CREATE TABLE Customers_3NF (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50)
);
INSERT INTO Customers_3NF (customer_id, customer_name)
SELECT DISTINCT customer_id, customer_name FROM Orders_2NF;

CREATE TABLE Orders_3NF (
    order_id INT PRIMARY KEY,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customers_3NF(customer_id)
);
INSERT INTO Orders_3NF (order_id, customer_id)
SELECT order_id, customer_id FROM Orders_2NF;

-- BCNF decomposition as presented in the practical PDF
CREATE TABLE Discounts_BCNF (
    discount_code VARCHAR(20) PRIMARY KEY,
    product_id INT,
    FOREIGN KEY (product_id) REFERENCES Products_2NF(product_id)
);
INSERT INTO Discounts_BCNF (discount_code, product_id)
SELECT DISTINCT discount_code, product_id FROM OrderDetails_2NF;

CREATE TABLE OrderItems_BCNF (
    order_id INT,
    discount_code VARCHAR(20),
    quantity INT,
    PRIMARY KEY (order_id, discount_code),
    FOREIGN KEY (order_id) REFERENCES Orders_3NF(order_id),
    FOREIGN KEY (discount_code) REFERENCES Discounts_BCNF(discount_code)
);
INSERT INTO OrderItems_BCNF (order_id, discount_code, quantity)
SELECT order_id, discount_code, quantity FROM OrderDetails_2NF;

-- Lossless-join check: compare the reconstructed rows with Sales_1NF.
SELECT
    o.order_id,
    d.product_id,
    c.customer_id,
    c.customer_name,
    p.product_name,
    oi.quantity,
    oi.discount_code
FROM Orders_3NF AS o
JOIN Customers_3NF AS c ON o.customer_id = c.customer_id
JOIN OrderItems_BCNF AS oi ON o.order_id = oi.order_id
JOIN Discounts_BCNF AS d ON oi.discount_code = d.discount_code
JOIN Products_2NF AS p ON d.product_id = p.product_id
ORDER BY o.order_id, d.product_id;

-- Dependency/update demonstration
UPDATE Customers_3NF
SET customer_name = 'Aarav S.'
WHERE customer_id = 501;
SELECT * FROM Customers_3NF;

-- Optional negative test from the PDF: this should fail because LAP10 is already a primary key.
-- Uncomment and run separately to observe the constraint violation:
-- INSERT INTO Discounts_BCNF (discount_code, product_id) VALUES ('LAP10', 103);
