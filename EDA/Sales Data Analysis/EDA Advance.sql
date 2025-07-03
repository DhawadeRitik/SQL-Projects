
SELECT * FROM fact_sales;
SELECT * FROM dim_customers;
SELECT * FROM dim_products;

--- BUSINESS PROBLEM 

-- 1. CHANGE OVER TIME 
 -- SALES OVER TIME 
   SELECT order_date,
   sales_amount
   FROM fact_sales
   WHERE order_date IS NOT NULL
   ORDER BY sales_amount;

-- SALES BY YEAR 
   SELECT 
   YEAR(order_date) AS years,
   SUM(sales_amount) AS total_sales ,
   COUNT(DISTINCT customer_key) AS total_customer,
   SUM(quantity) AS quantity_sold
   FROM fact_sales
   WHERE order_date IS NOT NULL
   GROUP BY YEAR(order_date)
   ORDER BY YEAR(order_date);

-- SEE THE REVENUE BY MONTH
   SELECT 
   MONTH(order_date) AS months,
   SUM(sales_amount) AS total_revenue ,
   COUNT(DISTINCT customer_key) AS total_customers,
   SUM(quantity) AS total_quantity_sold
   FROM fact_sales 
   WHERE order_date IS NOT NULL
   GROUP BY MONTH(order_date)
   ORDER BY MONTH(order_date);

   SELECT 
   DATETRUNC(MONTH,order_date) AS months,
   SUM(sales_amount) AS total_revenue ,
   COUNT(DISTINCT customer_key) AS total_customers,
   SUM(quantity) AS total_quantity_sold
   FROM fact_sales 
   WHERE order_date IS NOT NULL
   GROUP BY DATETRUNC(YEAR,order_date),DATETRUNC(MONTH,order_date)
   ORDER BY DATETRUNC(MONTH,order_date);

-- CUMULATIVE ANALYSIS 
-- CALCULATE THE TOTAL SALES PER MONTH ALSO THE RUNNING TOTAL 
	SELECT
	order_date,
	total_sale,
	-- USE WINDOW FUNCTION TO CALCULATE RUNNING TOTAL 
	SUM(total_sale) OVER(ORDER BY order_date) AS running_total_sales
	FROM (
	   SELECT 
	   DATETRUNC(MONTH,order_date) AS order_date,
	   SUM(sales_amount) AS total_sale
	   FROM fact_sales
	   WHERE order_date IS NOT NULL
	   GROUP BY DATETRUNC(MONTH,order_date)
	  ) A

	  -- RUNNING TOTAL BY YEAR
	SELECT
	order_year,
	total_sales,
	SUM(total_sales) OVER(ORDER BY order_year) AS running_total_sales
	FROM 
	(
	SELECT 
	  YEAR(order_date) AS order_year,
	  SUM(sales_amount) AS total_sales 
	  FROM fact_sales 
	  WHERE order_date IS NOT NULL
	  GROUP BY YEAR(order_date)
	  ) A
	  
 -- CALCULATE THE MOVING AVERAGE OF THE PRICE 
   SELECT 
   order_date,
   total_sales,
   avg_price,
   SUM(total_sales) OVER(ORDER BY order_date) AS running_total,
   AVG(avg_price) OVER(ORDER BY order_date) AS moving_avg
   FROM (
   SELECT 
   YEAR(order_date) AS order_date,
   SUM(sales_amount) AS total_sales ,
   AVG(price) AS avg_price
   FROM fact_sales
   WHERE order_date IS NOT NULL
   GROUP BY YEAR(order_date)
   ) A

--- PERFORMANCE ANALYSIS 
--- COMPARE THE CURRENT VALUE TO THE TARGET VALUE 

--- ANALYZE THE YEARLY PERFORMANCE OF THE PRODUCT 
--- BY COMPARING EACH PRODUCT SALES  TO BOTH ITS AVERAGE SALES PERFORMANCE AND THE PREVIOUS YEAR SALES 
  WITH yearly_sales AS (
  SELECT 
	YEAR(S.order_date) order_year,
	P.product_name,
	SUM(S.sales_amount) current_sale
	FROM fact_sales S
	JOIN dim_products P
	ON S.product_key = P.product_key
	WHERE order_date IS NOT NULL 
	GROUP BY YEAR(S.order_date),P.product_name
	) SELECT 
     order_year,
     product_name,
     current_sale,
	 AVG(current_sale) OVER(PARTITION BY product_name) AS avg_sale,
	 current_sale - AVG(current_sale) OVER(PARTITION BY product_name)  AS sale_diff,
	 CASE 
	     WHEN current_sale - AVG(current_sale) OVER(PARTITION BY product_name) > 0 THEN 'above average'
		 WHEN current_sale - AVG(current_sale) OVER(PARTITION BY product_name) < 0 THEN 'below average'
		 ELSE 'avg'
		 END AS sale_category
     FROM yearly_sales;
	  
-- ADD PREVIOUS YEAR SALE AND THE DIFFERENCE BETWEEN THE CURRENT YEAR AND THE PREVIOUS YEAR SALES 
     WITH yearly_sales AS (
  SELECT 
	YEAR(S.order_date) order_year,
	P.product_name,
	SUM(S.sales_amount) current_sale
	FROM fact_sales S
	JOIN dim_products P
	ON S.product_key = P.product_key
	WHERE order_date IS NOT NULL 
	GROUP BY YEAR(S.order_date),P.product_name
	) SELECT 
     order_year,
     product_name,
     current_sale,
	 AVG(current_sale) OVER(PARTITION BY product_name) AS avg_sale,
	 current_sale - AVG(current_sale) OVER(PARTITION BY product_name)  AS sale_diff,
	 CASE 
	     WHEN current_sale - AVG(current_sale) OVER(PARTITION BY product_name) > 0 THEN 'above average'
		 WHEN current_sale - AVG(current_sale) OVER(PARTITION BY product_name) < 0 THEN 'below average'
		 ELSE 'avg'
		 END AS sale_category,
	 LAG(current_sale) OVER(PARTITION BY product_name ORDER BY order_year) AS previous_year_sale,
	 current_sale -  LAG(current_sale) OVER(PARTITION BY product_name ORDER BY order_year) AS sale_diff,
	 CASE 
	     WHEN current_sale - LAG(current_sale) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
		 WHEN current_sale - LAG(current_sale) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
		 ELSE 'No Change'
		 END AS sale_category
     FROM yearly_sales;
---
--- PRT TO WHOLE 
-- PROPORTIONAL
-- WHICH CATEGORYCONSTRIBUTE THE MOST TO OVERALL SALE
   WITH category_sale AS (
   SELECT 
   P.category,
   SUM(S.sales_amount) AS total_revenue
   FROM fact_sales S
   JOIN dim_products P
   ON S.product_key = P.product_key
   GROUP BY P.category
   ) SELECT 
     category,
	 total_revenue,
	 SUM(total_revenue) OVER() overall_sale ,
	 CONCAT(ROUND(CAST(total_revenue AS FLOAT) / SUM(total_revenue) OVER() * 100,2),'%')  AS percentage_of_total
	 FROM category_sale
	 ORDER BY percentage_of_total DESC


-- DATA SEGMENTATION USING SQL
-- GROUP THE DATA BASED ON THE SPECIFIC RANGE 
-- SEGEMNT THE PRODUCT INTO CAST RANGE AND COUNT HOW MANY PRODUCT FALL INTO EACH SEGMENT
   WITH product_segment AS (
   SELECT 
   product_key,
   product_name,
   cost,
   CASE WHEN cost = 0 THEN '0 cost'
        WHEN cost < 0 AND cost < 100 THEN 'Below 100'
        WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'Above 1000'
	END AS cost_segment
	FROM DIM_products
	) SELECT 
	  cost_segment,
	  COUNT(product_key) AS total_product
	  FROM product_segment
	  GROUP BY cost_segment
	  ORDER BY total_product DESC

-- GROUP CUSTOMER INTO THREE SEGMENTS  BASED ON THERE SPENDING BEHAVIOUR :
   -- VIP : CUSTOMERS AT LEAST 12 MONTHS OF HISTORY AND SPENDING MORE THAN 5000
   -- REGULAR : CUSTOMERS AT LEAST 12 MONTHS OF HISTORY BUT SPENDING AT LEAST 5000 OR LESS 
   -- NEW CUSTOMER : CUSTOMER WITH THE LIFESPAN LESS THAN 12 MONTHS
-- AND FIND A TOTAL NUMBER OF CUSTOMER BY EACH GROUP 

   WITH customer_spending AS (
    SELECT 
        C.customer_key,
        SUM(S.sales_amount) AS total_spending,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM fact_sales S 
    JOIN dim_customers C 
        ON S.customer_key = C.customer_key
    GROUP BY C.customer_key
),
customer_status AS (
    SELECT 
        customer_key,
        CASE 
            WHEN total_spending > 5000 AND lifespan >= 12 THEN 'VIP'
            WHEN total_spending <= 5000 AND lifespan >= 12 THEN 'Regular'
            ELSE 'New Customer'
        END AS customer_status
    FROM customer_spending
)
SELECT 
    customer_status,
    COUNT(customer_key) AS total_customers
FROM customer_status
GROUP BY customer_status
order by total_customers DESC;

-- BUILD CUSTOMERS REPORT

/*
=========================================================================================================================
 CUSTOMER REPORT
=========================================================================================================================
PURPOSE : THIS REPORT CONSOLIDATES KEY CUSTOMERS METRICS AND BEHAVIOURS

HIGHLIGHTS :
      1. Gatherc essentials  fiels such as name , age and transaction details 
	  2. Segment customers into categories(VIP,Regular, New Customers) and age groups 
	  3. Aggregates customers level metrics :
	        -- total order 
			-- total sales 
			-- total quantity purchased
			-- total products 
			-- lifespan (in months)
	  4. calculate valuable KPI,S
	        -- recency (month since last order )
			-- average order value 
			-- average monthly spend
==========================================================================================================================
*/
/* -----------------------------------------------------------------------
1. Retrive core columns from table 
--------------------------------------------------------------------------*/
	WITH base_query AS (
		SELECT 
			S.order_number,
			S.quantity,
			S.product_key,
			S.order_date,
			S.sales_amount,
			C.customer_key,
			C.customer_number,
			CONCAT_WS(' ',C.first_name,C.last_name) AS full_name,
			DATEDIFF(YEAR , C.birthdate, GETDATE()) AS age
		FROM dim_customers C
		JOIN fact_sales S
		ON C.customer_key = S.customer_key
		WHERE order_date IS NOT NULL
	),customer_aggregation AS (
		SELECT  
				 customer_key,
				 customer_number,
				 full_name ,
				 age,
				COUNT(DISTINCT order_number) AS total_orders,
				SUM(sales_amount) AS total_revenue,
				COUNT(product_key) AS total_products,
				COUNT(DISTINCT customer_key) AS total_customers,
				SUM(quantity) AS total_quantity,
				MAX(order_date) AS last_order_date,
				DATEDIFF(YEAR,MIN(order_date),MAX(order_date)) AS lifespan
		  FROM base_query
		  GROUP BY   customer_key,
					 customer_number,
					 full_name ,
					 age
			)
			SELECT 
			         customer_key,
					 customer_number,
					 full_name ,
					 age,
					 CASE WHEN age < 20 THEN  'Under 20'
					      WHEN age BETWEEN 20 AND 29 THEN '20-29'
						  WHEN age BETWEEN 30 AND 39 THEN '30-39'
						  WHEN age BETWEEN 40 AND 49 THEN '40-49'
						  ELSE '50 and above'
					END AS age_group,
					 CASE 
						  WHEN lifespan >= 12 AND total_revenue >= 12 THEN 'VIP'
						  WHEN lifespan <= 12 AND total_revenue >= 12 THEN 'Regular'
						  ELSE 'New Customer'
					 END AS customer_status,
					 total_orders,
					 total_revenue,
					 total_products,
					 total_customers,
					 total_quantity,
					 last_order_date,
					 lifespan
			FROM customer_aggregation



    