-- ============================================================
-- Retail Sales Analysis — SQL Queries
-- Database: retail_sales_2023
-- Analyst: Deepthi Gaddameedi
-- Period:  January 2023 – December 2023
-- ============================================================
-- Tables used:
--   customers    (customer_id, city, age, gender, preferred_channel, registration_date)
--   products     (product_id, product_name, category, price, cost_price)
--   orders       (order_id, customer_id, order_date, status, payment_method, channel, city)
--   order_items  (item_id, order_id, product_id, category, quantity, unit_price,
--                 discount_pct, sale_price, line_total, cost_price, profit)
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- SECTION 1: OVERALL BUSINESS HEALTH
-- ────────────────────────────────────────────────────────────

-- Q1. Total revenue, orders, customers, and average order value
SELECT
    COUNT(DISTINCT o.order_id)                          AS total_orders,
    COUNT(DISTINCT o.customer_id)                       AS total_customers,
    ROUND(SUM(oi.line_total), 0)                        AS total_revenue,
    ROUND(SUM(oi.profit), 0)                            AS total_profit,
    ROUND(SUM(oi.profit) * 100.0 / SUM(oi.line_total), 1) AS profit_margin_pct,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 0) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered';


-- Q2. Monthly revenue trend — to spot seasonality
SELECT
    strftime('%Y-%m', o.order_date)   AS month,
    COUNT(DISTINCT o.order_id)         AS orders,
    COUNT(DISTINCT o.customer_id)      AS active_customers,
    ROUND(SUM(oi.line_total), 0)       AS revenue,
    ROUND(SUM(oi.profit), 0)           AS profit,
    ROUND(AVG(oi.line_total), 0)       AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY strftime('%Y-%m', o.order_date)
ORDER BY month;


-- Q3. Return and cancellation rate — business risk signal
SELECT
    status,
    COUNT(*)                                        AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 2: PRODUCT & CATEGORY ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Q4. Revenue and profit by category — which categories drive the business
SELECT
    oi.category,
    COUNT(DISTINCT o.order_id)                              AS orders,
    SUM(oi.quantity)                                        AS units_sold,
    ROUND(SUM(oi.line_total), 0)                            AS revenue,
    ROUND(SUM(oi.profit), 0)                                AS profit,
    ROUND(SUM(oi.profit) * 100.0 / SUM(oi.line_total), 1)  AS margin_pct,
    ROUND(AVG(oi.discount_pct), 1)                          AS avg_discount_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY oi.category
ORDER BY revenue DESC;


-- Q5. Top 10 best-selling products by revenue
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)                AS units_sold,
    ROUND(SUM(oi.line_total), 0)    AS revenue,
    ROUND(SUM(oi.profit), 0)        AS profit,
    ROUND(AVG(oi.discount_pct), 1)  AS avg_discount
FROM order_items oi
JOIN orders o   ON oi.order_id  = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;


-- Q6. Impact of discounts on profit margin
-- Are we over-discounting? This tells us where margin is being lost
SELECT
    CASE
        WHEN oi.discount_pct = 0          THEN '0% (No Discount)'
        WHEN oi.discount_pct BETWEEN 1 AND 10 THEN '1-10%'
        WHEN oi.discount_pct BETWEEN 11 AND 20 THEN '11-20%'
        ELSE '20%+'
    END                                                     AS discount_band,
    COUNT(DISTINCT o.order_id)                              AS orders,
    ROUND(SUM(oi.line_total), 0)                            AS revenue,
    ROUND(SUM(oi.profit) * 100.0 / SUM(oi.line_total), 1)  AS margin_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY discount_band
ORDER BY margin_pct DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 3: CUSTOMER BEHAVIOUR ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Q7. Customer segmentation using RFM logic
-- Recency: days since last order  |  Frequency: number of orders  |  Monetary: total spend
WITH customer_rfm AS (
    SELECT
        o.customer_id,
        c.city,
        c.age,
        c.gender,
        MAX(o.order_date)                                       AS last_order_date,
        COUNT(DISTINCT o.order_id)                              AS frequency,
        ROUND(SUM(oi.line_total), 0)                            AS monetary,
        CAST(julianday('2024-01-01') - julianday(MAX(o.order_date)) AS INTEGER) AS recency_days
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c    ON o.customer_id = c.customer_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id, c.city, c.age, c.gender
),
rfm_scored AS (
    SELECT *,
        CASE
            WHEN recency_days <= 30  THEN 5
            WHEN recency_days <= 60  THEN 4
            WHEN recency_days <= 120 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END AS r_score,
        CASE
            WHEN frequency >= 8  THEN 5
            WHEN frequency >= 5  THEN 4
            WHEN frequency >= 3  THEN 3
            WHEN frequency >= 2  THEN 2
            ELSE 1
        END AS f_score,
        CASE
            WHEN monetary >= 50000 THEN 5
            WHEN monetary >= 20000 THEN 4
            WHEN monetary >= 10000 THEN 3
            WHEN monetary >= 5000  THEN 2
            ELSE 1
        END AS m_score
    FROM customer_rfm
)
SELECT
    customer_id, city, age, gender,
    last_order_date, frequency, monetary, recency_days,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) AS rfm_score,
    CASE
        WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
        WHEN (r_score + f_score + m_score) >= 5  THEN 'At Risk'
        ELSE 'Lost'
    END AS customer_segment
FROM rfm_scored
ORDER BY rfm_score DESC;


-- Q8. Segment summary — how many in each group, what is their value
WITH customer_rfm AS (
    SELECT
        o.customer_id,
        MAX(o.order_date)  AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.line_total), 0) AS monetary,
        CAST(julianday('2024-01-01') - julianday(MAX(o.order_date)) AS INTEGER) AS recency_days
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
),
rfm_scored AS (
    SELECT *,
        CASE WHEN recency_days<=30 THEN 5 WHEN recency_days<=60 THEN 4
             WHEN recency_days<=120 THEN 3 WHEN recency_days<=180 THEN 2 ELSE 1 END AS r_score,
        CASE WHEN frequency>=8 THEN 5 WHEN frequency>=5 THEN 4
             WHEN frequency>=3 THEN 3 WHEN frequency>=2 THEN 2 ELSE 1 END AS f_score,
        CASE WHEN monetary>=50000 THEN 5 WHEN monetary>=20000 THEN 4
             WHEN monetary>=10000 THEN 3 WHEN monetary>=5000 THEN 2 ELSE 1 END AS m_score
    FROM customer_rfm
),
segmented AS (
    SELECT *,
        CASE
            WHEN (r_score+f_score+m_score)>=13 THEN 'Champions'
            WHEN (r_score+f_score+m_score)>=10 THEN 'Loyal Customers'
            WHEN (r_score+f_score+m_score)>=7  THEN 'Potential Loyalists'
            WHEN (r_score+f_score+m_score)>=5  THEN 'At Risk'
            ELSE 'Lost'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*)                           AS customers,
    ROUND(AVG(frequency), 1)           AS avg_orders,
    ROUND(AVG(recency_days), 0)        AS avg_recency_days,
    ROUND(AVG(monetary), 0)            AS avg_spend,
    ROUND(SUM(monetary), 0)            AS total_spend,
    ROUND(SUM(monetary)*100.0/SUM(SUM(monetary)) OVER(), 1) AS pct_of_revenue
FROM segmented
GROUP BY segment
ORDER BY avg_spend DESC;


-- Q9. New vs returning customer revenue split (month by month)
WITH order_sequence AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank
    FROM orders
    WHERE status = 'Delivered'
)
SELECT
    strftime('%Y-%m', os.order_date)  AS month,
    SUM(CASE WHEN os.order_rank = 1 THEN oi.line_total ELSE 0 END)  AS new_customer_revenue,
    SUM(CASE WHEN os.order_rank > 1 THEN oi.line_total ELSE 0 END)  AS returning_customer_revenue,
    COUNT(DISTINCT CASE WHEN os.order_rank = 1 THEN os.customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN os.order_rank > 1 THEN os.customer_id END) AS returning_customers
FROM order_sequence os
JOIN order_items oi ON os.order_id = oi.order_id
GROUP BY strftime('%Y-%m', os.order_date)
ORDER BY month;


-- ────────────────────────────────────────────────────────────
-- SECTION 4: CHANNEL & CITY ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Q10. Revenue by city — which markets are performing
SELECT
    o.city,
    COUNT(DISTINCT o.customer_id)               AS customers,
    COUNT(DISTINCT o.order_id)                  AS orders,
    ROUND(SUM(oi.line_total), 0)                AS revenue,
    ROUND(SUM(oi.profit), 0)                    AS profit,
    ROUND(SUM(oi.line_total)/COUNT(DISTINCT o.customer_id), 0) AS revenue_per_customer
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY o.city
ORDER BY revenue DESC;


-- Q11. Channel performance — Mobile App vs Website vs Store
SELECT
    o.channel,
    COUNT(DISTINCT o.order_id)                  AS orders,
    ROUND(SUM(oi.line_total), 0)                AS revenue,
    ROUND(AVG(oi.line_total), 0)                AS avg_order_value,
    ROUND(SUM(oi.profit)*100.0/SUM(oi.line_total),1) AS margin_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY o.channel
ORDER BY revenue DESC;


-- Q12. Payment method preference by city
SELECT
    city,
    payment_method,
    COUNT(*) AS orders,
    ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(PARTITION BY city),1) AS pct_in_city
FROM orders
WHERE status = 'Delivered'
GROUP BY city, payment_method
ORDER BY city, orders DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 5: COHORT RETENTION ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Q13. Monthly cohort retention — what % of customers who joined in month X
--      came back in subsequent months
WITH first_order AS (
    SELECT
        customer_id,
        strftime('%Y-%m', MIN(order_date)) AS cohort_month
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        f.cohort_month,
        strftime('%Y-%m', o.order_date) AS activity_month,
        COUNT(DISTINCT o.customer_id)    AS active_customers
    FROM orders o
    JOIN first_order f ON o.customer_id = f.customer_id
    WHERE o.status = 'Delivered'
    GROUP BY f.cohort_month, strftime('%Y-%m', o.order_date)
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_customers
    FROM first_order
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    cs.cohort_customers,
    ca.activity_month,
    ca.active_customers,
    ROUND(ca.active_customers * 100.0 / cs.cohort_customers, 1) AS retention_rate_pct
FROM cohort_activity ca
JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.activity_month;
