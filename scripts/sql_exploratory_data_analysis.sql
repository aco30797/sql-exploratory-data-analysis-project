-- Create schema only if it does not already exist
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'gold'
)
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO


-- DIMENSION vs MEASURE
-- Dimension = descriptive/categorical value used for grouping/filtering
-- Measure = numeric value that makes sense to aggregate (SUM, AVG...)

SELECT DISTINCT category -- values are not numeric, so it is dimension
FROM gold.dim_products

SELECT DISTINCT sales_amount -- values are numeric, so it is measure, make sense to aggregate - we can get total/ average sales...
FROM gold.fact_sales

SELECT DISTINCT product_name
FROM gold.dim_products

SELECT DISTINCT quantity
FROM gold.fact_sales

SELECT DISTINCT birthdate
FROM gold.dim_customers

-- Calculate average customer age
-- DATEDIFF calculates the difference between birthdate and today in years
SELECT DISTINCT 
AVG(DATEDIFF( year, birthdate, GETDATE())) as Avg_Age
FROM gold.dim_customers

SELECT DISTINCT customer_id --numeric, but not make sense to aggregate -> dimension
FROM gold.dim_customers


-- DATABASE EXPLORATION

-- Explore all objects in the Database
-- INFORMATION_SCHEMA contains metadata about the database
SELECT * FROM INFORMATION_SCHEMA.TABLES

--Explore all columns or specific columns in the Database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_sales'


-- DIMENSIONS EXPLORATION

-- Explore all countries our customers come from
SELECT DISTINCT country
FROM gold.dim_customers

-- Explore all product categories "The Major Divisions"
-- Shows hierarchy: Category -> Subcategory -> Product
SELECT DISTINCT category, subcategory, product_name
FROM gold.dim_products
ORDER BY 1,2,3


-- DATE EXPLORATION

-- Find the date of the first and the last order 
-- How many years of sales are available 
SELECT 
	MIN(order_date) as first_order, 
	MAX(order_date) as last_order,
	DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) as order_range_years
FROM gold.fact_sales

-- Find the youngest and the oldest customers
-- Earlier birthdate = older customer, later birthdate = younger customer
SELECT
	MIN(birthdate) as birthdate_oldest_customer,
	DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS years_oldest_customer,
	MAX(birthdate) as birthdate_youngest_customer,
	DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS years_youngest_customer
FROM gold.dim_customers


-- MEASURE EXPLORATION

-- Find the total sales
SELECT SUM(sales_amount) as total_sales
FROM gold.fact_sales

-- Find how many items are sold 
SELECT SUM (quantity) as sold_items
FROM gold.fact_sales

-- Find the average selling price 
SELECT AVG(price) as avg_price
FROM gold.fact_sales

-- Find the total number of orders
-- COUNT counts rows/order numbers including repeated order numbers
SELECT COUNT(order_number) AS num_with_duplicates
FROM gold.fact_sales

-- DISTINCT counts each order only once
SELECT COUNT(DISTINCT order_number) AS num_without_duplicates
FROM gold.fact_sales

-- Find the total number of products
SELECT COUNT(DISTINCT product_key) as number_of_products
FROM gold.dim_products

-- Find the total number of customers
SELECT COUNT(DISTINCT customer_key) as number_of_customers
FROM gold.dim_customers

-- Find the total number of customers that has placed an order
-- fact_sales contains only customers involved in sales
SELECT COUNT(DISTINCT customer_key) as number_of_customers
FROM gold.fact_sales


-- Generate a Report that shows all key metrics of the business
-- UNION ALL combines different KPIs vertically into one result/report

SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products', COUNT(product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers', COUNT(customer_key) FROM gold.dim_customers;


-- MAGNITUDE ANALYSIS 
-- Magnitude Analysis = compare a measure across different dimensions/categories
-- Pattern: aggregate measure (SUM/COUNT/AVG) + GROUP BY dimension

-- Find total customers by countries
-- Dimension = country | Measure = number of customers
SELECT 
	country, 
	COUNT(DISTINCT customer_key) as number_of_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY number_of_customers DESC

-- Find total customers by gender
-- Dimension = gender | Measure = number of customers
SELECT 
	gender, 
	COUNT(DISTINCT customer_key) as number_of_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY number_of_customers DESC

-- Find total products by category
-- Dimension = category | Measure = number of products
SELECT 
	category, 
	COUNT(DISTINCT product_key) as number_of_products
FROM gold.dim_products
GROUP BY category
ORDER BY number_of_products DESC

-- What is the average costs in each category?
-- Dimension = category | Measure = average cost
SELECT 
	category, 
	AVG(cost) as average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC

-- What is the total revenue generated for each category?
-- JOIN is needed because sales_amount is in fact_sales, while category is in dim_products
SELECT 
	dp.category,
	SUM(fc.sales_amount) AS total_revenue
FROM gold.fact_sales fc
LEFT JOIN gold.dim_products dp
ON dp.product_key = fc.product_key
GROUP BY category
ORDER BY total_revenue DESC

SELECT*
FROM gold.dim_customers 

SELECT*
FROM gold.fact_sales

-- Find total revenue is generated by each customer
-- JOIN connects customer information with their sales
-- GROUP BY creates one result per customer
SELECT 
	dc.customer_key,
	dc.first_name,
	SUM(fc.sales_amount) AS total_revenue
FROM gold.fact_sales fc
LEFT JOIN gold.dim_customers dc
ON dc.customer_key = fc.customer_key
GROUP BY dc.customer_key,
		 dc.first_name
ORDER BY total_revenue DESC

-- What is the distribution of sold items across countries?
-- SUM(quantity) shows how many items were sold to customers from each country
SELECT 
	dc.country, 
	SUM(fc.quantity) as total_sold_items
FROM gold.fact_sales fc
LEFT JOIN gold.dim_customers dc
ON fc.customer_key = dc.customer_key
GROUP BY dc.country
ORDER BY total_sold_items DESC


-- RANKING ANALYSIS
-- Ranking Analysis = order dimensions by a measure
-- Used for Top N / Bottom N analysis


-- Which 5 products generate the highest revenue?
-- TOP 5 + DESC = take the 5 products with the highest revenue

SELECT TOP 5
	dp.product_name,
	SUM(fc.sales_amount) AS total_revenue
FROM gold.fact_sales fc
LEFT JOIN gold.dim_products dp
ON dp.product_key = fc.product_key
GROUP BY dp.product_name
ORDER BY total_revenue DESC


-- Same task using ROW_NUMBER instead of TOP
-- ROW_NUMBER gives each product a unique position: 1, 2, 3, 4...
-- DESC means the highest revenue gets rank 1
-- Outer query keeps only ranks 1-5

SELECT *
FROM ( 
	SELECT 
	dp.product_name,
	SUM(fc.sales_amount) AS total_revenue,
	ROW_NUMBER() OVER (ORDER BY SUM(fc.sales_amount) DESC) AS rank_products
FROM gold.fact_sales fc
LEFT JOIN gold.dim_products dp
ON dp.product_key = fc.product_key
GROUP BY dp.product_name) t
WHERE rank_products<=5



-- What are the 5 worst-performing products in terms of sales?
-- TOP 5 + ASC = take the 5 products with the lowest revenue

SELECT TOP 5
	dp.product_name,
	SUM(fc.sales_amount) AS total_revenue
FROM gold.fact_sales fc
LEFT JOIN gold.dim_products dp
ON dp.product_key = fc.product_key
GROUP BY dp.product_name
ORDER BY total_revenue ASC


-- Same task using ROW_NUMBER
-- ASC means the lowest revenue gets rank 1

SELECT*
FROM(
	SELECT
	dp.product_name,
	SUM(fc.sales_amount) AS total_revenue,
	ROW_NUMBER() OVER (ORDER BY SUM(fc.sales_amount) ASC) as rank_products
FROM gold.fact_sales fc
LEFT JOIN gold.dim_products dp
ON dp.product_key = fc.product_key
GROUP BY dp.product_name) t
WHERE rank_products <=5


-- Find the Top 10 customers who have generated the highest revenue
-- Aggregate sales per customer, sort DESC and take first 10

SELECT TOP 10
	dc.customer_key,
	dc.first_name,
	SUM(fc.sales_amount) AS total_revenue
FROM gold.fact_sales fc
LEFT JOIN gold.dim_customers dc
ON dc.customer_key = fc.customer_key
GROUP BY dc.customer_key,
		 dc.first_name
ORDER BY total_revenue DESC


-- Find the 3 customers with the fewest orders placed
-- COUNT(DISTINCT order_number) counts unique orders for each customer
-- ASC puts customers with the fewest orders first
-- customer_key ASC is a tie-breaker when multiple customers have the same number of orders

SELECT TOP 3
	dc.customer_key,
	dc.first_name,
	COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales fc
LEFT JOIN gold.dim_customers dc
ON dc.customer_key = fc.customer_key
GROUP BY dc.customer_key,
		 dc.first_name
ORDER BY total_orders ASC,
		 dc.customer_key ASC

SELECT*
FROM gold.fact_sales



-- =============================================================================
-- CHANGE OVER TIME ANALYSIS
-- =============================================================================

-- Analyze sales performance over time

-- Calculate total sales for each order date
SELECT 
	order_date,
	SUM (sales_amount) as total_sales
FROM 
gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_date
ORDER BY order_date ASC


-- Analyze yearly and monthly sales performance
-- Calculate total sales, unique customers, and total quantity
SELECT 
	--YEAR(order_date) as  order_year,
	YEAR(order_date) as  order_year,
	MONTH(order_date) as order_month,
	SUM(sales_amount) as total_sales,
	COUNT (DISTINCT customer_key) as total_customers,
	SUM (quantity) as total_quantity 
FROM 
gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date) ASC
--GROUP BY YEAR(order_date)
--ORDER BY YEAR(order_date) ASC


-- Analyze yearly sales using DATETRUNC
SELECT 
	DATETRUNC(YEAR,order_date) as order_date,
	SUM(sales_amount) as total_sales,
	COUNT (DISTINCT customer_key) as total_customers,
	SUM (quantity) as total_quantity 
FROM 
gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date)
ORDER BY DATETRUNC(YEAR,order_date)
--GROUP BY DATETRUNC(month,order_date)
--ORDER BY DATETRUNC(month,order_date)


-- Format order dates by year and month for reporting
SELECT 
	FORMAT(order_date, 'yyyy-MMM') as order_date,
	SUM(sales_amount) as total_sales,
	COUNT (DISTINCT customer_key) as total_customers,
	SUM (quantity) as total_quantity 
FROM 
gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')


-- =============================================================================
-- CUMULATIVE ANALYSIS
-- =============================================================================

-- Calculate total sales per month
-- Calculate the running total of sales over time
-- Calculate the moving average of monthly average prices

SELECT 
	order_month,
	total_sales,
	SUM (total_sales) OVER (ORDER BY order_month) AS running_total_sales,
	AVG (average_price) OVER (ORDER BY order_month) as moving_avg_price--,
	--SUM (total_sales) OVER (PARTITION BY order_month ORDER BY order_month) AS running_total_sales_by_month
FROM
	(
	SELECT
			DATETRUNC(month,order_date) as order_month,
			SUM (sales_amount) as total_sales,
			AVG(price) as average_price
			FROM gold.fact_sales
			WHERE order_date IS NOT NULL
			GROUP BY DATETRUNC(month,order_date)
	)t


-- =============================================================================
-- PERFORMANCE ANALYSIS
-- =============================================================================

-- Analyze the yearly performance of products by comparing each product's sales to both:
-- its average sales performance and the previous year's sales.

-- Step 1: Calculate yearly sales for each product
;WITH yearly_product_sales AS (
SELECT
	YEAR(s.order_date) AS order_year,
	p.product_name,
	SUM(s.sales_amount) AS current_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
WHERE order_date IS NOT NULL 
GROUP BY YEAR(s.order_date) , p.product_name
)

-- Step 2: Compare current sales with average sales and previous year's sales
SELECT
order_year,
product_name,
current_sales,

-- Average sales performance
AVG(current_sales) OVER (PARTITION BY product_name) as avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name)  as diff_between_current_and_average_sales,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN ' Below Avg'
	 ELSE 'Avg'
	 END avg_change,

-- Previous year's sales (year-over-year analysis)
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as previous_year_sales,
current_sales -  LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as diff_between_current_and_previous_year_sales,
CASE WHEN current_sales -  LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)  > 0 THEN 'Increase'
	 WHEN current_sales -  LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)  < 0 THEN ' Decrease'
	 ELSE 'No Change'
	 END change_vs_previous_year
FROM yearly_product_sales;


-- =============================================================================
-- PART-TO-WHOLE ANALYSIS (PROPORTIONAL ANALYSIS)
-- =============================================================================

-- Analyze which product categories contribute the most to overall sales
-- Calculate each category's percentage of total sales

-- Step 1: Calculate total sales for each category
WITH category_sales AS (
SELECT 
	p.category, 
	SUM(s.sales_amount) AS total_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY p.category
)

-- Step 2: Calculate overall sales and each category's contribution
SELECT
	category,
	total_sales,
	SUM (total_sales) OVER() as overall_sales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM (total_sales) OVER()) * 100,2), '%')  percentage
FROM category_sales
ORDER BY total_sales DESC;


-- =============================================================================
-- DATA SEGMENTATION
-- =============================================================================

-- Segment products into cost ranges and count how many products fall into each segment

-- Step 1: Classify products into cost ranges using CASE WHEN
WITH product_segments AS(
SELECT
	product_key,
	product_name,
	cost,
	CASE WHEN cost<100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		 ELSE 'Above 1000'
		 END cost_range
FROM gold.dim_products
)

-- Step 2: Count the number of products in each cost range
SELECT
	cost_range,
	COUNT(product_key) as number_products
FROM product_segments
GROUP BY cost_range
ORDER BY number_products DESC;


/*
Group customers into three segments based on their spending behavior:
    - VIP: Customers with at least 12 months of history and spending more than €5,000.
    - Regular: Customers with at least 12 months of history but spending €5,000 or less.
    - New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group.
*/

-- Step 1: Calculate total spending and customer lifespan
WITH cte_customer_spending AS(
SELECT
c.customer_key,
SUM(s.sales_amount) as total_spending,
	MIN(order_date) as first_order,
	MAX(order_date) as last_order,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) as lifespan
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON s.customer_key = c.customer_key
GROUP BY c.customer_key
),

-- Step 2: Classify customers into VIP, Regular, and New
cte_customer_group AS(  -- new CTE without WITH, and with , between 
SELECT
customer_key,
CASE WHEN lifespan >= 12 and total_spending > 5000 THEN 'VIP'
	WHEN lifespan >= 12 and total_spending < 5000 THEN 'Regular'
	WHEN lifespan < 12 THEN 'New'
	END customer_group
FROM cte_customer_spending
)

-- Step 3: Count customers in each segment
SELECT
customer_group,
COUNT(customer_key) as total_customers
FROM cte_customer_group
GROUP BY customer_group
ORDER BY COUNT(customer_key) ASC;
