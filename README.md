# Olist Brazilian E-Commerce: SQL & Tableau End-to-End Analytics

An end-to-end data analytics and business intelligence project analyzing 100k+ real-world Brazilian e-commerce orders from the Olist Dataset. This project integrates relational database modeling, advanced multi-table SQL queries, and an interactive Tableau executive dashboard to assess operational drivers across revenue growth, logistics latency, customer satisfaction, and payment methods.

---

## Architecture Overview

1. **Relational Ingestion & Storage:** Raw transaction CSV files loaded into a normalized MySQL relational schema enforcing foreign keys and integrity constraints.
2. **SQL Analytical Layer:** 10+ business queries leveraging Common Table Expressions (CTEs), window functions, date transformations, and conditional aggregations.
3. **Tableau Semantic Modeling:** Relational noodle mapping between normalized tables, calculation-based delimiter cleaning, and geographic hierarchy definition.
4. **Interactive Executive BI Dashboard:** 5-panel interactive dashboard with cross-filtering across geography, category hierarchies, and fulfillment metrics.

---

## Relational Schema & Tables Modeled

* **orders:** Order status and lifecycle timestamps (`order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`, `order_estimated_delivery_date`).
* **order_items:** Line items, product IDs, seller IDs, shipping limits, item prices, and freight values.
* **order_payments:** Payment sequences, payment types (`credit_card`, `boleto`, `voucher`, `debit_card`), installments, and transaction values.
* **order_reviews:** Review IDs, order associations, numerical review scores (1 to 5), titles, comments, and survey timestamps.
* **customers & sellers:** Unique customer and seller identifiers, zip code prefixes, city names, and 2-letter state codes.
* **products & product_category_name_translation:** Product dimensions, category names in Portuguese, and English translation mappings.

---

## Core SQL Analytical Queries

### 1. Monthly Revenue & MoM Growth Dynamics
Utilizes CTEs and the `LAG()` window function to track monthly sales trajectory alongside month-over-month percentage changes:

```sql
WITH MonthlySales AS (
    SELECT 
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS sale_month,
        ROUND(SUM(price), 2) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
)
SELECT 
    sale_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY sale_month) AS prev_month_revenue,
    ROUND(((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY sale_month)) 
           / LAG(monthly_revenue) OVER (ORDER BY sale_month)) * 100, 2) AS mom_growth_pct
FROM MonthlySales
ORDER BY sale_month;
