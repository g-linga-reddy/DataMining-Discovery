--  Drop Existing Tables
PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS OrderDetails;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;

PRAGMA foreign_keys = ON;


-- Create Tables

-- Customers: personal info and membership
CREATE TABLE Customers (
    id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    gender TEXT CHECK(gender IN ('Male','Female','Other')),
    membership TEXT CHECK(membership IN ('Bronze','Silver','Gold','Platinum')),
    dob DATE,
    registration DATE
);

-- Products: store item details
CREATE TABLE Products (
    id INTEGER PRIMARY KEY,
    name TEXT,
    category TEXT CHECK(category IN ('Electronics','Clothing','Home','Beauty','Toys')),
    price REAL,
    stock INTEGER,
    discount REAL CHECK(discount BETWEEN 0 AND 50)
);

-- Orders: store customer purchases
CREATE TABLE Orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_date DATE,
    total REAL,
    payment TEXT CHECK(payment IN ('Cash','Card','Online')),
    FOREIGN KEY(customer_id) REFERENCES Customers(id)
);

-- OrderDetails: link orders and products
CREATE TABLE OrderDetails (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    PRIMARY KEY(order_id, product_id),
    FOREIGN KEY(order_id) REFERENCES Orders(id),
    FOREIGN KEY(product_id) REFERENCES Products(id)
);


-- Customers (1000 rows)

WITH RECURSIVE counter(x) AS (
    SELECT 1 UNION ALL SELECT x+1 FROM counter WHERE x < 1000
)
INSERT INTO Customers(first_name, last_name, gender, membership, dob, registration)
SELECT
    'First' || x,
    'Last' || x,
    CASE ABS(RANDOM() % 3)
        WHEN 0 THEN 'Male'
        WHEN 1 THEN 'Female'
        ELSE 'Other'
    END,
    CASE ABS(RANDOM() % 4)
        WHEN 0 THEN 'Bronze'
        WHEN 1 THEN 'Silver'
        WHEN 2 THEN 'Gold'
        ELSE 'Platinum'
    END,
    DATE('1970-01-01', '+' || (ABS(RANDOM()) % 18000) || ' days'),
    DATE('2020-01-01', '+' || (ABS(RANDOM()) % 1000) || ' days')
FROM counter;


--  Products (50 rows)
WITH RECURSIVE counter(x) AS (
    SELECT 1 UNION ALL SELECT x+1 FROM counter WHERE x < 50
)
INSERT INTO Products(name, category, price, stock, discount)
SELECT
    CASE ABS(RANDOM() % 10)
        WHEN 0 THEN 'Laptop'
        WHEN 1 THEN 'Smartphone'
        WHEN 2 THEN 'Headphones'
        WHEN 3 THEN 'T-Shirt'
        WHEN 4 THEN 'Jeans'
        WHEN 5 THEN 'Coffee Maker'
        WHEN 6 THEN 'Vacuum Cleaner'
        WHEN 7 THEN 'Lipstick'
        WHEN 8 THEN 'Action Figure'
        ELSE 'Board Game'
    END,
    CASE
        WHEN x <= 10 THEN 'Electronics'
        WHEN x <= 20 THEN 'Clothing'
        WHEN x <= 30 THEN 'Home'
        WHEN x <= 40 THEN 'Beauty'
        ELSE 'Toys'
    END,
    CASE
        WHEN x <= 10 THEN ROUND(200 + ABS(RANDOM()%800),2)
        WHEN x <= 20 THEN ROUND(10 + ABS(RANDOM()%90),2)
        WHEN x <= 30 THEN ROUND(20 + ABS(RANDOM()%180),2)
        WHEN x <= 40 THEN ROUND(5 + ABS(RANDOM()%45),2)
        ELSE ROUND(15 + ABS(RANDOM()%85),2)
    END,
    ABS(RANDOM()%100)+1,  -- stock
    ROUND(ABS(RANDOM()%20),2)  -- discount %
FROM counter;


-- Orders and OrderDetails (1000 orders, 2000 items)
-- Totals are calculated during insertion

WITH RECURSIVE counter(x) AS (
    SELECT 1 UNION ALL SELECT x+1 FROM counter WHERE x < 1000
)
INSERT INTO Orders(customer_id, order_date, total, payment)
SELECT
    ABS(RANDOM()%1000)+1,
    DATE('2023-01-01','+'||ABS(RANDOM()%365)||' days'),
    0,
    CASE ABS(RANDOM()%3)
        WHEN 0 THEN 'Cash'
        WHEN 1 THEN 'Card'
        ELSE 'Online'
    END
FROM counter;

-- Insert OrderDetails and calculate totals dynamically
WITH order_list AS (
    SELECT id AS order_id FROM Orders
),
product_list AS (
    SELECT id, price, discount FROM Products
),
comb AS (
    SELECT o.order_id, p.id AS product_id, p.price, p.discount
    FROM order_list o
    JOIN product_list p
),
selected AS (
    SELECT * FROM comb ORDER BY RANDOM() LIMIT 2000
)
INSERT INTO OrderDetails(order_id, product_id, quantity)
SELECT
    order_id,
    product_id,
    ABS(RANDOM()%3)+1
FROM selected;

-- Update totals immediately after OrderDetails insertion
UPDATE Orders
SET total = (
    SELECT ROUND(SUM(Products.price * od.quantity * (1 - Products.discount/100.0)),2)
    FROM OrderDetails od
    JOIN Products ON od.product_id = Products.id
    WHERE od.order_id = Orders.id
);
