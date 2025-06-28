use pizza_sales;
select * from orders;
select * from pizzas;
select * from order_details ;


-- Basic Questions 
-- Q1.Calculate the total revenue generated from pizza sales
SELECT 
  SUM(p.price * o.quantity) AS total_sales
FROM pizzas p
  JOIN order_details o
ON p.pizza_id = o.pizza_id;

-- Q2. Retrieve the total number of orders placed.
SELECT COUNT(*) FROM orders;

-- Q3. Identify the highest-priced pizza
SELECT 
    pt.name ,
    p.price
FROM pizzas p
    JOIN pizza_types pt 
ON p.pizza_type_id = pt.pizza_type_id
where p.price = (SELECT  MAX(price) FROM pizzas);

-- Q4. Identify the most common pizza size ordered.
SELECT 
    p.size,
    SUM(od.quantity) AS quantity_ordered
FROM pizzas p
JOIN order_details od
ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY quantity_ordered DESC
LIMIT 1;

-- Q5. List the top 5 most ordered pizza types along with their quantities.
SELECT 
pt.name,
SUM(od.quantity) total_quantity
FROM pizza_types pt
JOIN pizzas p 
ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od 
ON p.pizza_id =od.pizza_id
GROUP BY 1
ORDER BY total_quantity DESC 
LIMIT 5;


-- INTERMEDIATE LEVEL QUESTIONS
-- Q1 . Join the necessary tables to find the total quantity of each pizza category ordered.
	SELECT 
	    pt.category,
		SUM(od.quantity) total_quantity
	FROM pizza_types pt
	JOIN pizzas p 
	ON pt.pizza_type_id = p.pizza_type_id
	JOIN order_details od 
	ON p.pizza_id =od.pizza_id
	GROUP BY 1
	ORDER BY total_quantity DESC ;
    
-- Q2. Determine the distribution of orders by hour of the day.
    SELECT HOUR(time) Hours ,
    COUNT(*) Order_placed
    FROM orders
    GROUP BY HOUR(time)
    ORDER BY 2 DESC;

-- Q3. Determine the distribution of the quantity sold by hour of the day
	SELECT 
		HOUR(o.time) Hours,
		COUNT(od.order_id) order_placed
	FROM orders o 
	JOIN order_details od 
	ON o.order_id = od.order_id
	GROUP BY 1
	ORDER BY order_placed DESC ;
    
-- Q4. Join relevant tables to find the category-wise distribution of pizzas.
     SELECT 
		category ,
        COUNT(name) pizza_count
     FROM pizza_types
     GROUP BY category
     ORDER BY pizza_count DESC;
	
-- Q5. Group the orders by date and calculate the average number of pizzas ordered per day.
	WITH daily_orders AS 
    (
		SELECT 
			o.date  Days,
			SUM(od.quantity) quantity_orders
		FROM orders o
		JOIN order_details od
		ON o.order_id = od.order_id
        GROUP BY Days
	) SELECT 
        ROUND(AVG(quantity_orders),0)  average_qantity_ordered
      FROM  daily_orders;
      
-- Q6. Determine the top 3 most ordered pizza types based on revenue.
   SELECT
	   pt.name ,
	   SUM(od.quantity * p.price) as total_revenue
   FROM pizzas p
   JOIN order_details od
   ON p.pizza_id = od.pizza_id 
   JOIN pizza_types pt
   ON p.pizza_type_id = pt.pizza_type_id
   GROUP BY   pt.name 
   ORDER BY total_revenue DESC
   LIMIT 3;
   
-- ADVANCE LEVEL 
-- Q7. Calculate the percentage contribution of each pizza type to total revenue.
WITH pct_contri AS (
   SELECT
       pt.name ,
	   ROUND(SUM(od.quantity * p.price),2) as total_revenue
   FROM pizzas p
   JOIN order_details od
   ON p.pizza_id = od.pizza_id 
   JOIN pizza_types pt
   ON p.pizza_type_id = pt.pizza_type_id
   GROUP BY   pt.name 
)
	SELECT 
		name,
		 total_revenue ,
		 CONCAT(ROUND(
		total_revenue * 100 /SUM(total_revenue) OVER(),2),'%') contribution_pct
	FROM pct_contri
	ORDER BY contribution_pct DESC;
    
-- Q8. Category Wiae Percentage Constribution To Revenue 
    WITH pct_contri AS (
   SELECT
       pt.category ,
	   ROUND(SUM(od.quantity * p.price),2) as total_revenue
   FROM pizzas p
   JOIN order_details od
   ON p.pizza_id = od.pizza_id 
   JOIN pizza_types pt
   ON p.pizza_type_id = pt.pizza_type_id
   GROUP BY   pt.category 
)
	SELECT 
		category,
		 total_revenue ,
		 CONCAT(ROUND(
		total_revenue * 100 /SUM(total_revenue) OVER(),2),'%') contribution_pct
	FROM pct_contri
	ORDER BY contribution_pct DESC;

    
-- Q9. Analyze the cumulative revenue generated over time.
	WITH cum_rev AS (
        SELECT 
			o.date ,
			ROUND(SUM(p.price * od.quantity),2) as total_revenue 
		 FROM pizzas p
		 JOIN  order_details od
		 ON p.pizza_id = od.pizza_id
		 JOIN orders o
		 ON od.order_id = o.order_id
		 GROUP BY  o.date
   ) SELECT 
         date ,
         total_revenue ,
         SUM(total_revenue) OVER(ORDER BY date) AS cumulative_revenue
	FROM cum_rev 
    ORDER  BY date;
    
-- Q10. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
	WITH most_ord_pizza AS (
      SELECT 
		   pt.name,
		   pt.category,
		   SUM(p.price * od.quantity) as total_revenue
	   FROM pizzas p
	   JOIN order_details od 
	   ON p.pizza_id = od.pizza_id
	   JOIN pizza_types pt
	   ON p.pizza_type_id = pt.pizza_type_id
	   GROUP BY   pt.name, pt.category
   ), rank_revenue as (
   SELECT 
      name ,
      category ,
      total_revenue ,
      RANK() OVER(PARTITION BY category ORDER BY total_revenue) AS ranks 
   FROM  most_ord_pizza
  ) 
    SELECT  
          name ,
          category ,
		  total_revenue 
	FROM  rank_revenue
    WHERE ranks <= 1
    


