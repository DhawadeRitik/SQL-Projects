use monday_coffee_db;

-- Explore the data
select * from city;
select count(*) from city;

select * from customers;
select count(*) as total_customers from customers;

select * from products ;
select count(*) as total_products from products;


select * from sales;
select count(*) from sales;


-- check for null value and the duplicate value 
-- check for null value 
select * from city
where city_rank  is null;

desc city;

desc customers;
select * from customers 
where customer_id is null;

desc sales;
select * from sales
where sale_id is null;



-- Solve the business problem 

-- Q.1 Coffee Consumers Count
-- --> How many people in each city are estimated to consume coffee, given that 25% of the population does?
select 
city_name ,
concat(round((population * 0.25)/1000000,2)," M")as coffee_consumer_in_million ,
city_rank
from city 
order by coffee_consumer_in_million desc;

-- Q.2 Total Revenue from Coffee Sales
-- > What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select 
   sum(total) as total_revenue,
   year(sale_date) as sale_year,
   quarter( sale_date) as quarters
from sales
where 
   year(sale_date) = 2023 
          and 
   quarter( sale_date)  = 4 
group by 
    year(sale_date) ,
    quarter( sale_date) ;

-- for city name 
select
   c.city_name ,
   sum(s.total) as total_revenue,
   year(s.sale_date) as sale_year,
   quarter(s.sale_date) as quarters
from 
   sales s
join 
	customers cu 
     on 
s.customer_id =  cu.customer_id
join 
	city c 
on 
	cu.city_id = c.city_id 
where 
    year(s.sale_date) = 2023 
          and 
    quarter(s.sale_date)  = 4 
group by 
    year(s.sale_date) ,
    quarter(s.sale_date),
    c.city_name
order by 
    total_revenue desc;


-- Q.3 Sales Count for Each Product
-- > How many units of each coffee product have been sold?
select 
	p.product_name,
	count(p.product_id) product_sold
from 
    products p
join 
    sales s
on 
    p.product_id = s.product_id
group by 
	p.product_name
order by 
    product_sold desc;


-- Q.4 Average Sales Amount per City
-- > What is the average sales amount per customer in each city?
select 
    ci.city_name ,
    sum(s.total) as tota_revenue,
    count(distinct s.customer_id) as customer_count,
    round(sum(s.total)/count(distinct s.customer_id),2) as average_sales_per_customer 
from 
	customers  c
join 
	sales s
on 
	c.customer_id = s.customer_id
join 
	city ci
on 
	c.city_id = ci.city_id
group by 
	ci.city_name

-- Q.5 City Population and Coffee Consumers (25%)
-- > Provide a list of cities along with their populations and estimated coffee consumers.
-- > return city_name, total current cx, estimated coffee consumers (25%)
select 
   c.city_name ,
   concat(round((c.population * 0.25)/1000000,2),' Million') as coffee_consumer ,
   count(distinct s.customer_id) as unique_customer
from 
   city c
join 
   customers cu
on
   c.city_id = cu.city_id
join 
   sales s 
on 
   cu.customer_id = s.customer_id
group by 
   c.city_name,
   coffee_consumer
   
-- Q.6 Top Selling Products by City
-- > What are the top 3 selling products in each city based on sales volume?
 with top_selling_products as (
    select 
        ci.city_name,
        p.product_name,
        count(s.product_id) as total_orders,
        dense_rank() over (partition by ci.city_name order by count(s.product_id) desc) as ranks
    from products p
    join sales s on p.product_id = s.product_id
    join customers c on s.customer_id = c.customer_id
    join city ci on c.city_id = ci.city_id
    group by 
        ci.city_name,
        p.product_name
)
select 
    city_name, 
    product_name, 
    total_orders
from top_selling_products
where ranks <= 3
order by city_name;


-- Q.7 Customer Segmentation by City
-- > How many unique customers are there in each city who have purchased coffee products?
select 
	ci.city_name,
	count(distinct s.customer_id) as unique_customers
from city ci 
join customers c on ci.city_id = c.city_id 
join sales s on c.customer_id = s.customer_id 
where s.product_id in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
group by ci.city_name 

 
-- Q.8 Average Sale vs Rent
-- > Find each city and their average sale per customer and avg rent per customer
select 
	c.city_name ,
	c.estimated_rent,
	sum(s.total) total_revenue ,
	count(distinct s.customer_id) as unique_customer,
	round(sum(s.total)/count(distinct s.customer_id),2) average_sales,
	round(c.estimated_rent/count(distinct s.customer_id),2) average_rent
from city c 
join customers cs 
on c.city_id = cs.city_id
join sales s 
on cs.customer_id = s.customer_id 
group by c.city_name,c.estimated_rent
order by  average_rent desc


-- Q.9 Monthly Sales Growth
-- > Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- > by each city
with monthly_sales as 
(
	select 
		c.city_name ,
		month(s.sale_date) as sale_month ,
		year(s.sale_date) as year,
		sum(s.total) total_sale 
	from city c 
	join customers cs 
	on c.city_id  = cs.city_id
	join sales s 
	on cs.customer_id = s.customer_id
	group by c.city_name , month(s.sale_date),year(s.sale_date)
	order by sale_month 
),previous_month_sales as (
	 select 
	  	city_name, sale_month,year,
	  	total_sale,
	  	lag(total_sale) over(partition by city_name order by year,sale_month) as previous_month_sale
	  from monthly_sales
  )select 
   		city_name , sale_month ,year,
   		total_sale, previous_month_sale ,
   		concat(round((total_sale - previous_month_sale)*100/previous_month_sale,2),' %') as growth_decline_in_pct 
   from previous_month_sales
   where previous_month_sale is not null
   order by city_name,year,sale_month;
  
-- Q.10 Market Potential Analysis
-- >  Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consume

select 
	c.city_name,
	count(distinct s.customer_id) total_customer,
	c.estimated_rent as total_rent,
	concat(round((c.population * 0.25)/1000000,2),' M') estimated_coffee_consumer,
	concat(round(sum(s.total)/1000000,2),' M') total_sales,
	round(sum(s.total)/count(distinct s.customer_id),2) as average_sales,
	round(c.estimated_rent / count(distinct s.customer_id),2) as average_rent_per_cust
from city c 
join customers cs 
on c.city_id = cs.city_id
join sales s 
on cs.customer_id = s.customer_id
group by c.city_name,total_rent,c.population
order by total_sales desc
limit 3
	
   
   
   
   
   
   
   
   
   
   
   
   
   
	