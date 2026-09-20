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
## Tableau Executive Dashboard Architecture
* The dashboard visualizes business operations across 5 integrated worksheets linked by interactive cross-filtering:

* Monthly Revenue & MoM Growth: Dual-axis chart with revenue bars and a MoM percentage growth line highlighting seasonal surges (Black Friday November 2017 peak).

* Top 10 Product Categories: Ranked horizontal bar chart highlighting top grossing categories (health_beauty, watches_gifts, bed_bath_table) sorted descending with direct revenue labels.

* Delivery Delay vs. Review Rating: Diverging comparison showing satisfaction drops caused by shipping bottlenecks.

* Brazil Regional Late Delivery Heatmap: Filled geographic map plotting all 27 Brazilian states, shaded using a red-green diverging color palette based on state-level delay percentages.

* Payment Methods & Installments: Distribution bar chart sorting transaction methods (credit_card, boleto, voucher, debit_card) with color gradients indicating average installment counts.

## Data Modeling Adjustments Applied in Tableau
* Relationship Calculation: Handled escaped quote anomalies in review exports by using relationship string calculations: REPLACE(["Order Id"], '"', '') to successfully relate orders and reviews without dropping records.

* Geographic Role Configuration: Assigned geographic role of State/Province to Customer State, mapping fixed country assignment to Brazil to resolve unmatched region codes.

* Date Parsing Logic: Applied explicit timestamp checks:
IF ISNULL([Order Delivered Customer Date]) THEN "No Delivery Date" ELSEIF [Order Delivered Customer Date] > [Order Estimated Delivery Date] THEN "Late" ELSE "On-time" END to separate valid deliveries from in-transit or missing records.

## Analytical Findings & Business Takeaways
* Logistics Latency Is the Primary Driver of Negative Ratings:

On-time orders maintain an average rating of 4.29 / 5.0.

Delayed shipments drop to 2.57 / 5.0 (a drop of over 1.7 stars), indicating that logistical delays represent the single largest point of customer dissatisfaction.

* Severe Regional Supply Chain Disparities:

Core southeastern states (SP, PR, SC) demonstrate low late delivery rates between 2.8% and 5.0%.

Distant northern and northeastern states (MA, AL, AP, CE) face delay rates between 20.0% and 23.0%, underscoring the necessity of forward distribution centers in the north.

* Installment-Driven Purchasing Power:

Credit cards drive over 73% of transaction volume and carry an average of 3.5 installments, highlighting that financing options are essential for customer conversion in top categories.
