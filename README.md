# SQL Exploratory & Advanced Data Analysis Project

## Project Overview

This project demonstrates practical SQL skills through exploratory data analysis, advanced analytical queries, and business reporting using Microsoft SQL Server (T-SQL).

The analysis focuses on understanding sales performance, customer behavior, product trends, and key business metrics using a structured data warehouse.

## Tools & Technologies

- **Microsoft SQL Server** – Database management and SQL queries
- **SQL Server Management Studio (SSMS)** – Query development and execution
- **T-SQL** – Data exploration, transformations, and analytical queries
- **Git & GitHub** – Version control and project documentation
- **Docker** – Local SQL Server environment

## SQL Skills Demonstrated

- Data exploration and database structure analysis
- Filtering, grouping, and aggregations
- Joins and Common Table Expressions (CTEs)
- Window functions (`SUM OVER`, `AVG OVER`, `LAG`, `ROW_NUMBER`)
- Date and time analysis
- Conditional logic using `CASE WHEN`
- Customer and product segmentation
- Business KPI calculations
- Creating SQL views for reporting

## Key Analyses

### Database Exploration
Exploring tables, schemas, dimensions, measures, and available data to understand the database structure.

### Change Over Time Analysis
Analyzing sales trends by day, month, and year to understand how business performance changes over time.

### Cumulative Analysis
Calculating running sales totals and moving averages to identify long-term trends.

### Product Performance Analysis
Comparing yearly product sales against average performance and previous-year results using window functions.

### Part-to-Whole Analysis
Measuring how individual product categories contribute to total revenue.

### Data Segmentation
Grouping products into cost ranges and classifying customers into VIP, Regular, and New segments based on purchasing behavior.

### Customer Reporting
Creating a customer-level SQL report containing sales KPIs, order history, customer segmentation, recency, and spending metrics.

### Product Reporting
Creating a product-level SQL report containing revenue, order activity, product performance, and sales KPIs.

## Repository Structure

```text
sql-exploratory-data-analysis-project/
│
├── datasets/
│   └── flat-files/
│       ├── dim_customers.csv
│       ├── dim_products.csv
│       └── fact_sales.csv
│
├── scripts/
│   ├── README.md
│   ├── sql_exploratory_data_analysis.sql
│   ├── report_customers.sql
│   └── report_products.sql
│
├── README.md
└── LICENSE
```

## Project Objectives

The main objectives of this project are to:

- Explore and understand a relational data warehouse
- Transform raw business data into meaningful analytical insights
- Evaluate sales, customer, and product performance
- Apply advanced SQL techniques to real-world business questions
- Build reusable SQL reports to support data-driven decision-making

## Learning Context

This project was developed as a hands-on learning project while following *The Complete SQL Bootcamp: Go from Zero to Hero* by Data With Baraa.

The SQL queries and analyses were practiced, adapted, and documented as part of my SQL learning journey.
