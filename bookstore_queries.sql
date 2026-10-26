/*
 * Name: [YOUR FULL NAME]
 * Student ID: [YOUR STUDENT ID]
 * Assignment: Homework 7 - Advanced SQL (INS3064)
 * Date: 2026-10-26
 * Database: bookstore_db (from Homework 6)
 * Target: MySQL 8.0+
 *
 * Instructions: Import bookstore_db.sql from Homework 6 first, then run
 * this file in the SQL tab in phpMyAdmin (or use MySQL SOURCE).
 *
 * All expected output examples below come from Homework 6's sample data.
 * Financial amounts are in USD. Since the question does not specify
 * excluding order statuses, order totals here include pending, paid,
 * shipped, and completed orders (gross ordered value, not necessarily
 * accounting-recognized revenue). No orders are cancelled in the sample.
 */

USE bookstore_db;

-- Query 1: List every book with its title, ISBN and author name.
-- A book with two authors appears in two rows; LEFT JOIN also keeps books
-- that have not yet been linked to an author.
SELECT
    b.title AS book_title,
    b.isbn AS isbn,
    a.full_name AS author_name
FROM books AS b
LEFT JOIN book_authors AS ba ON ba.book_id = b.book_id
LEFT JOIN authors AS a ON a.author_id = ba.author_id
ORDER BY b.book_id, a.full_name;
/*
Expected output (11 rows):
| book_title                    | isbn          | author_name      |
|-------------------------------|---------------|------------------|
| Practical SQL for Beginners   | 9781390000016 | Nguyen Minh Anh  |
| Practical SQL for Beginners   | 9781390000016 | Tran Quoc Bao    |
| Learning Python Step by Step  | 9781390000023 | Tran Quoc Bao    |
| Modern Web Development        | 9781390000030 | Emily Carter     |
| Modern Web Development        | 9781390000030 | Nguyen Minh Anh  |
| Small Business Essentials     | 9781390000047 | David Wilson     |
| Everyday Vietnamese Cooking   | 9781390000054 | Le Thu Ha        |
| The River at Dawn             | 9781390000061 | Pham Ngoc Linh   |
| Personal Finance Made Simple  | 9781390000078 | David Wilson     |
| Personal Finance Made Simple  | 9781390000078 | Emily Carter     |
| Building Better Habits        | 9781390000085 | Emily Carter     |
*/

-- Query 2: Show orders with the customer, order date, book, quantity and
-- line total. Historical unit_price is used rather than the catalog price.
-- LEFT JOIN preserves an order even if it has no items yet.
SELECT
    o.order_id AS order_id,
    c.full_name AS customer_name,
    o.order_date AS order_date,
    b.title AS book_title,
    oi.quantity AS quantity,
    CAST(COALESCE(oi.quantity * oi.unit_price, 0.00)
         AS DECIMAL(12,2)) AS line_total
FROM orders AS o
INNER JOIN customers AS c ON c.customer_id = o.customer_id
LEFT JOIN order_items AS oi ON oi.order_id = o.order_id
LEFT JOIN books AS b ON b.book_id = oi.book_id
ORDER BY o.order_date DESC, o.order_id DESC, b.book_id;
/*
Expected output (14 rows; USD):
| order_id | customer_name  | order_date          | book_title                   | quantity | line_total |
|----------|----------------|---------------------|------------------------------|----------|------------|
| 6        | Hoang Thu Ha   | 2026-09-20 11:40:00 | Personal Finance Made Simple | 1        | 22.00      |
| 6        | Hoang Thu Ha   | 2026-09-20 11:40:00 | Building Better Habits       | 2        | 39.90      |
| 5        | Nguyen Van An  | 2026-09-15 09:10:00 | Learning Python Step by Step | 1        | 29.50      |
| 5        | Nguyen Van An  | 2026-09-15 09:10:00 | Modern Web Development       | 1        | 34.00      |
| 4        | Pham Ngoc Dung | 2026-09-10 16:30:00 | Practical SQL for Beginners  | 2        | 49.80      |
| 4        | Pham Ngoc Dung | 2026-09-10 16:30:00 | The River at Dawn            | 1        | 15.90      |
| 4        | Pham Ngoc Dung | 2026-09-10 16:30:00 | Building Better Habits       | 1        | 19.95      |
| 3        | Le Minh Cuong  | 2026-09-06 08:45:00 | Small Business Essentials    | 1        | 21.75      |
| 3        | Le Minh Cuong  | 2026-09-06 08:45:00 | Personal Finance Made Simple | 1        | 22.00      |
| 2        | Tran Thi Bich  | 2026-09-03 14:20:00 | Everyday Vietnamese Cooking  | 2        | 37.00      |
| 2        | Tran Thi Bich  | 2026-09-03 14:20:00 | The River at Dawn            | 1        | 15.90      |
| 1        | Nguyen Van An  | 2026-09-01 10:00:00 | Practical SQL for Beginners  | 1        | 23.90      |
| 1        | Nguyen Van An  | 2026-09-01 10:00:00 | Learning Python Step by Step | 1        | 29.50      |
| 1        | Nguyen Van An  | 2026-09-01 10:00:00 | Modern Web Development       | 1        | 32.00      |
*/

-- Query 3: Show each book once, together with its publisher and an
-- alphabetical comma-separated list of every category it belongs to.
-- This query JOINs four tables: books, publishers, book_categories, categories.
SELECT
    b.title AS book_title,
    p.name AS publisher_name,
    COALESCE(
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', '),
        'No category'
    ) AS category_names
FROM books AS b
INNER JOIN publishers AS p ON p.publisher_id = b.publisher_id
LEFT JOIN book_categories AS bc ON bc.book_id = b.book_id
LEFT JOIN categories AS c ON c.category_id = bc.category_id
GROUP BY b.book_id, b.title, p.name
ORDER BY b.title;
/*
Expected output (8 rows):
| book_title                   | publisher_name          | category_names          |
|------------------------------|-------------------------|-------------------------|
| Building Better Habits       | Horizon Knowledge Press | Lifestyle               |
| Everyday Vietnamese Cooking  | Riverlight Books        | Lifestyle               |
| Learning Python Step by Step | Lotus Learning Press    | Programming, Technology |
| Modern Web Development       | Bright Path Publishing  | Programming, Technology |
| Personal Finance Made Simple | Horizon Knowledge Press | Business, Lifestyle     |
| Practical SQL for Beginners  | Lotus Learning Press    | Programming, Technology |
| Small Business Essentials    | Bright Path Publishing  | Business                |
| The River at Dawn            | Riverlight Books        | Fiction                 |
*/

-- Query 4: For each book, calculate the number of copies sold and
-- the total value of those copies, sorted by revenue (highest first).
-- Books that have not sold appear with zero quantity and zero revenue.
SELECT
    b.title AS book_title,
    COALESCE(SUM(oi.quantity), 0) AS total_quantity_sold,
    CAST(COALESCE(SUM(oi.quantity * oi.unit_price), 0.00)
         AS DECIMAL(12,2)) AS total_revenue
FROM books AS b
LEFT JOIN order_items AS oi ON oi.book_id = b.book_id
GROUP BY b.book_id, b.title
ORDER BY total_revenue DESC, b.title;
/*
Expected output (8 rows; USD):
| book_title                   | total_quantity_sold | total_revenue |
|------------------------------|---------------------|---------------|
| Practical SQL for Beginners  | 3                   | 73.70         |
| Modern Web Development       | 2                   | 66.00         |
| Building Better Habits       | 3                   | 59.85         |
| Learning Python Step by Step | 2                   | 59.00         |
| Personal Finance Made Simple | 2                   | 44.00         |
| Everyday Vietnamese Cooking  | 2                   | 37.00         |
| The River at Dawn            | 2                   | 31.80         |
| Small Business Essentials    | 1                   | 21.75         |
*/

-- Query 5: Summarize each customer's distinct orders and total spending.
-- LEFT JOIN includes customers with no orders. COUNT(DISTINCT order_id)
-- prevents counting the same order several times because it has many items.
SELECT
    c.full_name AS customer_name,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    CAST(COALESCE(SUM(oi.quantity * oi.unit_price), 0.00)
         AS DECIMAL(12,2)) AS total_amount_spent
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
LEFT JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_amount_spent DESC, c.full_name;
/*
Expected output (5 rows; USD; all sample customers have orders):
| customer_name  | number_of_orders | total_amount_spent |
|----------------|------------------|--------------------|
| Nguyen Van An  | 2                | 148.90             |
| Pham Ngoc Dung | 1                | 85.65              |
| Hoang Thu Ha   | 1                | 61.90              |
| Tran Thi Bich  | 1                | 52.90              |
| Le Minh Cuong  | 1                | 43.75              |
If a new customer has no order, the query reports 0 orders and 0.00 spent.
*/

-- Query 6: Find books whose catalog price is higher than the
-- average catalog price of all books, using a scalar subquery.
SELECT
    b.title AS book_title,
    b.price AS price
FROM books AS b
WHERE b.price > (
    SELECT AVG(b2.price)
    FROM books AS b2
)
ORDER BY b.price DESC, b.title;
/*
Expected output (3 rows; average book price = 23.3125 USD):
| book_title                   | price |
|------------------------------|-------|
| Modern Web Development       | 34.00 |
| Learning Python Step by Step | 29.50 |
| Practical SQL for Beginners  | 24.90 |
*/

-- Query 7: Find the author(s) associated with the highest total number
-- of books sold. A CTE calculates quantities, and a subquery with MAX()
-- returns ALL tied best-selling authors (not LIMIT 1). Each co-author
-- receives full credit for a copy of their jointly authored book.
WITH author_sales AS (
    SELECT
        a.author_id AS author_id,
        a.full_name AS author_name,
        COALESCE(SUM(oi.quantity), 0) AS total_quantity_sold
    FROM authors AS a
    LEFT JOIN book_authors AS ba ON ba.author_id = a.author_id
    LEFT JOIN order_items AS oi ON oi.book_id = ba.book_id
    GROUP BY a.author_id, a.full_name
)
SELECT
    author_name,
    total_quantity_sold
FROM author_sales
WHERE total_quantity_sold = (
    SELECT MAX(total_quantity_sold)
    FROM author_sales
)
ORDER BY author_name;
/*
Expected output (1 row; ties would create more rows):
| author_name  | total_quantity_sold |
|--------------|---------------------|
| Emily Carter | 7                   |
*/

-- Query 8: Show customers who wrote more than two reviews with ratings
-- of at least three stars; lower-rated reviews are NOT counted.
SELECT
    c.full_name AS customer_name,
    COUNT(r.review_id) AS review_count
FROM customers AS c
INNER JOIN reviews AS r ON r.customer_id = c.customer_id
WHERE r.rating >= 3
GROUP BY c.customer_id, c.full_name
HAVING COUNT(r.review_id) > 2
ORDER BY review_count DESC, c.full_name;
/*
Expected output (2 rows):
| customer_name  | review_count |
|----------------|--------------|
| Nguyen Van An  | 3            |
| Pham Ngoc Dung | 3            |
*/

-- Query 9: Create a reusable sales-and-reviews summary view with one row
-- per book. Sales and reviews are grouped SEPARATELY before joining, so
-- the many-to-many JOINs do not accidentally multiply quantities or ratings.
-- Unsold books display zero sales; unreviewed books display NULL rating.
CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_book_sales_summary AS
SELECT
    b.title AS book_title,
    b.isbn AS isbn,
    p.name AS publisher_name,
    COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
    CAST(COALESCE(s.total_revenue, 0.00)
         AS DECIMAL(12,2)) AS total_revenue,
    r.average_review_rating AS average_review_rating,
    COALESCE(r.number_of_reviews, 0) AS number_of_reviews
FROM books AS b
INNER JOIN publishers AS p ON p.publisher_id = b.publisher_id
LEFT JOIN (
    SELECT
        oi.book_id AS book_id,
        SUM(oi.quantity) AS total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items AS oi
    GROUP BY oi.book_id
) AS s ON s.book_id = b.book_id
LEFT JOIN (
    SELECT
        rv.book_id AS book_id,
        ROUND(AVG(rv.rating), 2) AS average_review_rating,
        COUNT(rv.review_id) AS number_of_reviews
    FROM reviews AS rv
    GROUP BY rv.book_id
) AS r ON r.book_id = b.book_id;

-- Query 9 (verification): Display all rows returned by the new view.
SELECT
    book_title,
    isbn,
    publisher_name,
    total_quantity_sold,
    total_revenue,
    average_review_rating,
    number_of_reviews
FROM v_book_sales_summary
ORDER BY isbn;
/*
Expected output (8 rows; USD):
| book_title                   | isbn          | publisher_name          | total_quantity_sold | total_revenue | average_review_rating | number_of_reviews |
|------------------------------|---------------|-------------------------|---------------------|---------------|-----------------------|-------------------|
| Practical SQL for Beginners  | 9781390000016 | Lotus Learning Press    | 3                   | 73.70         | 4.50                  | 2                 |
| Learning Python Step by Step | 9781390000023 | Lotus Learning Press    | 2                   | 59.00         | 4.00                  | 1                 |
| Modern Web Development       | 9781390000030 | Bright Path Publishing  | 2                   | 66.00         | 5.00                  | 1                 |
| Small Business Essentials    | 9781390000047 | Bright Path Publishing  | 1                   | 21.75         | 3.00                  | 1                 |
| Everyday Vietnamese Cooking  | 9781390000054 | Riverlight Books        | 2                   | 37.00         | 4.00                  | 1                 |
| The River at Dawn            | 9781390000061 | Riverlight Books        | 2                   | 31.80         | 4.00                  | 2                 |
| Personal Finance Made Simple | 9781390000078 | Horizon Knowledge Press | 2                   | 44.00         | 4.00                  | 1                 |
| Building Better Habits       | 9781390000085 | Horizon Knowledge Press | 3                   | 59.85         | 5.00                  | 1                 |
*/

-- Query 10: Report all 12 months of the CURRENT calendar year, even when
-- no orders exist in a month. The recursive CTE generates month numbers;
-- the second CTE uses date functions, JOINs and GROUP BY to aggregate sales.
-- COUNT(DISTINCT order_id) avoids counting an order once per order item.
WITH RECURSIVE months AS (
    SELECT 1 AS month_number
    UNION ALL
    SELECT month_number + 1
    FROM months
    WHERE month_number < 12
),
monthly_sales AS (
    SELECT
        MONTH(o.order_date) AS month_number,
        COUNT(DISTINCT o.order_id) AS number_of_orders,
        COALESCE(SUM(oi.quantity), 0) AS total_items_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders AS o
    LEFT JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_date >= MAKEDATE(YEAR(CURDATE()), 1)
      AND o.order_date < DATE_ADD(
            MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 1 YEAR
          )
    GROUP BY MONTH(o.order_date)
)
SELECT
    m.month_number AS month_number,
    MONTHNAME(STR_TO_DATE(
        CONCAT(YEAR(CURDATE()), '-', LPAD(m.month_number, 2, '0'), '-01'),
        '%Y-%m-%d'
    )) AS month_name,
    COALESCE(ms.number_of_orders, 0) AS number_of_orders,
    COALESCE(ms.total_items_sold, 0) AS total_items_sold,
    CAST(COALESCE(ms.total_revenue, 0.00)
         AS DECIMAL(12,2)) AS total_revenue
FROM months AS m
LEFT JOIN monthly_sales AS ms ON ms.month_number = m.month_number
ORDER BY m.month_number;
/*
Expected output when run in year 2026 (12 rows; USD):
| month_number | month_name | number_of_orders | total_items_sold | total_revenue |
|--------------|------------|------------------|------------------|---------------|
| 1            | January    | 0                | 0                | 0.00          |
| 2            | February   | 0                | 0                | 0.00          |
| 3            | March      | 0                | 0                | 0.00          |
| 4            | April      | 0                | 0                | 0.00          |
| 5            | May        | 0                | 0                | 0.00          |
| 6            | June       | 0                | 0                | 0.00          |
| 7            | July       | 0                | 0                | 0.00          |
| 8            | August     | 0                | 0                | 0.00          |
| 9            | September  | 6                | 17               | 393.10        |
| 10           | October    | 0                | 0                | 0.00          |
| 11           | November   | 0                | 0                | 0.00          |
| 12           | December   | 0                | 0                | 0.00          |
In a later year, the dynamic CURRENT-year filter will give different totals.
*/
