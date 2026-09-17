CREATE DATABASE olist_ecommerce;
USE olist_ecommerce;


# -- - - - - - - tables - -  - - -- - - - - - - - 
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DECIMAL(10,6),
    geolocation_lng DECIMAL(10,6),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id) REFERENCES orders(order_id),
    ADD CONSTRAINT fk_order_items_products FOREIGN KEY (product_id) REFERENCES products(product_id),
    ADD CONSTRAINT fk_order_items_sellers FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE order_payments
    ADD CONSTRAINT fk_order_payments_orders FOREIGN KEY (order_id) REFERENCES orders(order_id);


SET SESSION sql_mode = '';
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
ALTER TABLE order_reviews
    ADD CONSTRAINT fk_order_reviews_orders FOREIGN KEY (order_id) REFERENCES orders(order_id);


# - - - - - - - - - - - - - - - Queries - - - - - - - - - - - - - - - - 
-- 1. Create and populate the Temporary Table once
USE olist_ecommerce;
DROP TEMPORARY TABLE IF EXISTS temp_monthly_revenue;

# using temp table for query 1,2 
CREATE TEMPORARY TABLE temp_monthly_revenue AS
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
       ROUND(SUM(oi.price), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month;


-- Query 1: Revenue trend by month
SELECT month,
       revenue
FROM temp_monthly_revenue
ORDER BY month;


-- Query 2. Month-over-Month (MoM) growth rate
SELECT month,
       revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) 
             / LAG(revenue) OVER (ORDER BY month) * 100, 1) AS MoM_growth_pct
FROM temp_monthly_revenue
ORDER BY month;


-- Query 3. top 10 product category by revenue 
SELECT t.product_category_name_english, ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;

-- similarly can find the products with least revenue, to analyse and find areas of improvement


# query 4.  Rank sellers by revenue within their state (window function):
SELECT s.seller_state, s.seller_id, ROUND(SUM(oi.price), 2) AS revenue,
       RANK() OVER (PARTITION BY s.seller_state ORDER BY SUM(oi.price) DESC) AS state_rank
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_state, s.seller_id;


# query 5. Delivery delay vs. review score (does late delivery hurt ratings?):
SELECT
  CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
       THEN 'Late' ELSE 'On-time' END AS delivery_status,
  ROUND(AVG(r.review_score), 2) AS avg_review_score,
  COUNT(*) AS num_orders
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;



# query 6. Average delivery delay in days:
SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)), 1)
       AS avg_days_early_or_late
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


# query 7. Payment type distribution:
SELECT payment_type, COUNT(*) AS num_payments,
       ROUND(AVG(payment_installments), 1) AS avg_installments
FROM order_payments
GROUP BY payment_type
ORDER BY num_payments DESC;


# query 8. Repeat customers (self-service RFM-lite):
SELECT customer_unique_id, COUNT(DISTINCT o.order_id) AS num_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY customer_unique_id
HAVING num_orders > 1
ORDER BY num_orders DESC;

# query 9. to find late_delivery_percentage per region 
SELECT 
    c.customer_state AS region,
    COUNT(o.order_id) AS total_delivered_orders,
    SUM(CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
            ELSE 0 
        END) AS late_deliveries,
    ROUND(
        SUM(CASE 
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
                ELSE 0 
            END) * 100.0 / COUNT(o.order_id), 
        2
    ) AS late_delivery_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_delivery_rate_pct DESC;


# query 10. Top 5 states by average order value:
SELECT c.customer_state, ROUND(AVG(order_total), 2) AS avg_order_value
FROM (
    SELECT o.order_id, o.customer_id, SUM(oi.price) AS order_total
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
) sub
JOIN customers c ON sub.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_order_value DESC
LIMIT 5;


#query 11 Customer Cohort Retention Analysis
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp,
        DATE_FORMAT(
            MIN(o.order_purchase_timestamp) OVER(PARTITION BY c.customer_unique_id), 
            '%Y-%m-01'
        ) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_intervals AS (
    SELECT 
        customer_unique_id,
        cohort_month,
        TIMESTAMPDIFF(
            MONTH, 
            STR_TO_DATE(cohort_month, '%Y-%m-%d'), 
            DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
        ) AS month_number
    FROM customer_orders o
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN month_number = 1 THEN customer_unique_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN month_number = 2 THEN customer_unique_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN month_number = 3 THEN customer_unique_id END) AS month_3
FROM cohort_intervals
GROUP BY cohort_month
ORDER BY cohort_month;


# query 12. Logistics & Freight Efficiency by Route - Calculates the average freight burden and transit time between customer and seller states to uncover logistics bottlenecks.
SELECT s.seller_state,
       c.customer_state,
       COUNT(DISTINCT o.order_id) AS total_orders,
       ROUND(AVG(oi.freight_value), 2) AS avg_freight,
       ROUND(AVG(oi.freight_value / (oi.price + oi.freight_value)) * 100, 2) AS freight_cost_share_pct,
       ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date)), 1) AS avg_transit_days
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_state, c.customer_state
HAVING total_orders >= 50
ORDER BY avg_transit_days DESC;

# query 13. Market Basket Analysis (Top Co-Purchased Categories) - Finds pairs of product categories most frequently purchased together in the same order.
SELECT t1.product_category_name_english AS category_a,
       t2.product_category_name_english AS category_b,
       COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 
  ON oi1.order_id = oi2.order_id 
  AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
JOIN product_category_translation t1 ON p1.product_category_name = t1.product_category_name
JOIN product_category_translation t2 ON p2.product_category_name = t2.product_category_name
WHERE t1.product_category_name_english != t2.product_category_name_english
GROUP BY category_a, category_b
ORDER BY times_bought_together DESC
LIMIT 10;

# query 14. Order Cancellation & Fulfillment Failure Rate - Identifies product categories with the highest cancellation and unavailability rates.
SELECT COALESCE(t.product_category_name_english, 'Unknown') AS category,
       COUNT(o.order_id) AS total_orders,
       SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) AS canceled_orders,
       SUM(CASE WHEN o.order_status = 'unavailable' THEN 1 ELSE 0 END) AS unavailable_orders,
       ROUND(SUM(CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 ELSE 0 END) 
             * 100.0 / COUNT(o.order_id), 2) AS cancellation_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
GROUP BY category
HAVING total_orders >= 100
ORDER BY cancellation_rate_pct DESC
LIMIT 10;


# some more queries:
-- # query. Running total of revenue (window function, CTE):
WITH daily AS (
    SELECT DATE(o.order_purchase_timestamp) AS order_date, SUM(oi.price) AS revenue
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY order_date
)
SELECT order_date, revenue,
       SUM(revenue) OVER (ORDER BY order_date) AS running_total
FROM daily ORDER BY order_date;



