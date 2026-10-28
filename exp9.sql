-- Experiment 9: Railway booking table with at least 5,000 rows and index benchmarking.
-- Based on the supplied PDF; corrected obvious PDF text-extraction spacing errors.

DROP TABLE IF EXISTS Railway_Booking;
CREATE TABLE Railway_Booking (
    booking_id INT PRIMARY KEY,
    passenger_name VARCHAR(100) NOT NULL,
    train_no INT NOT NULL,
    train_name VARCHAR(100) NOT NULL,
    source_station VARCHAR(100) NOT NULL,
    destination_station VARCHAR(100) NOT NULL,
    journey_date DATE NOT NULL,
    seat_no INT NOT NULL,
    coach VARCHAR(10) NOT NULL,
    ticket_class VARCHAR(30) NOT NULL,
    fare DECIMAL(10,2) NOT NULL,
    booking_status VARCHAR(20) NOT NULL
);

-- Generate exactly 5,000 rows using a number sequence.
INSERT INTO Railway_Booking (
    booking_id, passenger_name, train_no, train_name, source_station,
    destination_station, journey_date, seat_no, coach, ticket_class, fare, booking_status
)
SELECT
    n,
    CONCAT('Passenger_', n),
    12000 + (n % 50),
    CASE
        WHEN n % 5 = 0 THEN 'Rajdhani Express'
        WHEN n % 5 = 1 THEN 'Shatabdi Express'
        WHEN n % 5 = 2 THEN 'Duronto Express'
        WHEN n % 5 = 3 THEN 'Vande Bharat'
        ELSE 'Garib Rath'
    END,
    CASE
        WHEN n % 5 = 0 THEN 'Delhi'
        WHEN n % 5 = 1 THEN 'Mumbai'
        WHEN n % 5 = 2 THEN 'Lucknow'
        WHEN n % 5 = 3 THEN 'Bengaluru'
        ELSE 'Hyderabad'
    END,
    CASE
        WHEN n % 5 = 0 THEN 'Mumbai'
        WHEN n % 5 = 1 THEN 'Delhi'
        WHEN n % 5 = 2 THEN 'Delhi'
        WHEN n % 5 = 3 THEN 'Chennai'
        ELSE 'Pune'
    END,
    DATE_ADD('2026-01-01', INTERVAL (n % 365) DAY),
    1 + (n % 72),
    CASE WHEN n % 3 = 0 THEN 'A1' WHEN n % 3 = 1 THEN 'B1' ELSE 'S1' END,
    CASE WHEN n % 3 = 0 THEN 'AC First Class'
         WHEN n % 3 = 1 THEN 'AC 2 Tier' ELSE 'Sleeper' END,
    500 + (n % 1500),
    CASE WHEN n % 4 = 0 THEN 'CONFIRMED'
         WHEN n % 4 = 1 THEN 'WAITING'
         WHEN n % 4 = 2 THEN 'CANCELLED' ELSE 'RAC' END
FROM (
    SELECT ones.n + tens.n * 10 + hundreds.n * 100 + thousands.n * 1000 + 1 AS n
    FROM (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) ones
    CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) tens
    CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) hundreds
    CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) thousands
) AS numbers
WHERE n <= 5000;

SELECT COUNT(*) AS total_records FROM Railway_Booking;
SELECT * FROM Railway_Booking LIMIT 10;

-- Benchmark before indexing
SELECT * FROM Railway_Booking WHERE train_no = 12010;
EXPLAIN SELECT * FROM Railway_Booking WHERE train_no = 12010;

SELECT * FROM Railway_Booking WHERE journey_date = '2026-05-15';
EXPLAIN SELECT * FROM Railway_Booking WHERE journey_date = '2026-05-15';

-- Single-column index and benchmark after indexing
CREATE INDEX idx_train_no ON Railway_Booking(train_no);
SELECT * FROM Railway_Booking WHERE train_no = 12010;
EXPLAIN SELECT * FROM Railway_Booking WHERE train_no = 12010;

-- Optional timing; SHOW PROFILES may not be supported by every MySQL platform.
-- SET profiling = 1;
-- SELECT * FROM Railway_Booking WHERE train_no = 12010;
-- SHOW PROFILES;

-- Composite index
CREATE INDEX idx_train_date ON Railway_Booking(train_no, journey_date);
SELECT * FROM Railway_Booking
WHERE train_no = 12010 AND journey_date = '2026-05-15';
EXPLAIN SELECT * FROM Railway_Booking
WHERE train_no = 12010 AND journey_date = '2026-05-15';

-- Composite index with a date range
SELECT * FROM Railway_Booking
WHERE train_no = 12010
  AND journey_date BETWEEN '2026-05-01' AND '2026-05-31';
EXPLAIN SELECT * FROM Railway_Booking
WHERE train_no = 12010
  AND journey_date BETWEEN '2026-05-01' AND '2026-05-31';

-- Leftmost-prefix rule: train_no is the leading column of idx_train_date.
EXPLAIN SELECT * FROM Railway_Booking WHERE train_no = 12010;
EXPLAIN SELECT * FROM Railway_Booking WHERE journey_date = '2026-05-15';

SHOW INDEX FROM Railway_Booking;
SELECT COUNT(*) AS total_records FROM Railway_Booking;
SELECT * FROM Railway_Booking LIMIT 10;
