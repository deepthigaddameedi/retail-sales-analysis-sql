Retail Sales Analysis — SQL + Excel Project
Analyst: Deepthi Gaddameedi  
Period: January 2023 – December 2023  
Tools: SQL (SQLite) · Python (data generation) · Excel (dashboard)  
Dataset: 500 customers · 2,212 orders · 5,552 line items · 8 Indian cities
---
What This Project Is About
I built this project to analyse one full year of retail sales data for an Indian e-commerce business. The goal was to answer the questions a business manager would actually ask: which categories make the most money, which customers are worth retaining, and where is the company growing or losing ground.
All analysis was done in SQL first, then summarised in Excel for stakeholder reporting.
---
Key Results
Metric	Value
Total Revenue	₹4.05 Crore
Total Profit	₹1.58 Crore
Profit Margin	39.1%
Total Orders	1,690 (delivered)
Avg Order Value	₹23,955
---
What the SQL Queries Cover
The file `sql/retail_analysis.sql` contains 13 queries across 5 sections:
Section 1 — Business Health
Overall revenue, profit, and margin
Monthly trend to identify seasonality
Return and cancellation rate
Section 2 — Product Analysis
Revenue and margin by category
Top 10 products by revenue
Impact of discounts on profit margin
Section 3 — Customer Behaviour
RFM segmentation (Recency, Frequency, Monetary)
Customer segment summary with revenue share
New vs returning customer revenue split by month
Section 4 — Channel & City Analysis
Revenue by city across 8 Indian markets
Mobile App vs Website vs Store performance
Payment method preference by city
Section 5 — Cohort Retention
Monthly cohort retention — what % of customers came back each month
---
Findings
1. Electronics dominates but concentrates risk  
Electronics = 61% of revenue but also drives most returns. Books and Grocery have the thinnest margins.
2. Q4 is make-or-break  
October–December contributed 50% of annual revenue. The business is heavily seasonal.
3. Champions (155 customers) generate 51% of revenue  
31% of customers are Champions. Losing even 10% of this group would be a serious revenue hit.
4. Bengaluru underperforms  
Fewest customers and lowest revenue despite being a top-tier metro. Either acquisition is weak or the product mix doesn't suit the market.
5. UPI is the dominant payment method  
Consistent with national trends. COD is still significant in Tier 2 cities.
---
Project Structure
```
retail-sales-analysis/
├── README.md
├── sql/
│   └── retail_analysis.sql          # All 13 SQL queries with comments
├── data/
│   ├── customers.csv                # 500 customers
│   ├── products.csv                 # 113 products across 8 categories
│   ├── orders.csv                   # 2,212 orders
│   └── order_items.csv              # 5,552 line items
├── excel/
│   └── Retail_Sales_Analysis_2023.xlsx  # 5-sheet dashboard
└── reports/
    ├── chart1_monthly_revenue.png
    ├── chart2_category_analysis.png
    ├── chart3_customer_segments.png
    └── chart4_city_performance.png
```
---
How to Run the SQL
```bash
# Using SQLite (no installation needed on most systems)
sqlite3 retail.db < sql/retail_analysis.sql

# Or load the CSVs into any SQL tool:
# MySQL Workbench, DBeaver, PostgreSQL, or SQL Server
# Table names: customers, products, orders, order_items
```
Charts
![Monthly Revenue](reports/chart1_monthly_revenue.png)
![Category Analysis](reports/chart2_category_analysis.png)
![Customer Segments](reports/chart3_customer_segments.png)
![City Performance](reports/chart4_city_performance.png)
