select * from customers;
SELECT * FROM resturants;
SELECT * from orders; 
SELECT * FROM riders;
SELECT * FROM deliveries;

-- Q1 Q1.Write a Query to find the top 5 most frequently ordered dishes 
-- by customer called  "Akhil Reddy" in the last 1 year

SELECT
    customer_name,
    dishes,
    total_dishes
FROM (
    SELECT
        c.customer_id,
        c.customer_name,
        o.order_item AS dishes,
        COUNT(o.order_id) AS total_dishes,
        DENSE_RANK() OVER (ORDER BY COUNT(o.order_id) DESC) AS rnk
    FROM
        orders o
        JOIN customers c ON o.customer_id = c.customer_id
    WHERE
        o.order_date >= CURDATE() - INTERVAL 1 YEAR
        AND c.customer_name = 'Akhil Reddy'
    GROUP BY
        c.customer_id,
        c.customer_name,
        o.order_item
) AS t
WHERE
    rnk <= 5
ORDER BY
    rnk;
    
-- Q2 Popular time slots
-- Identify the time slots during which more orders are placed.Based on 2 hour interval

-- FIRST APPROACH--

SELECT 
	CASE
		WHEN HOUR(order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
		WHEN HOUR(order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
		WHEN HOUR(order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
		WHEN HOUR(order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
		WHEN HOUR(order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
		WHEN HOUR(order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
		WHEN HOUR(order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
		WHEN HOUR(order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
		WHEN HOUR(order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
		WHEN HOUR(order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
		WHEN HOUR(order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
		WHEN HOUR(order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
	END AS time_slot,
	COUNT(order_id) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY order_count DESC;

-- Q3 Order value analysis
-- find the average order value per customer who has palced more than 750 orders
-- return customername and average order value( AOV)


Select
		c.customer_id,
		c.customer_name,
		count(order_id) as total_count,
		sum(o.total_amount) as total_spend
FROM
	orders o
	left join customers c on o.customer_id = c.customer_id

Group by 1
having count(order_id) > 750;

-- Q4 High value customer
-- list the customers who hace spend more than 100K in total on food orders
-- return customer_name and customer_id

SELECT
	c.customer_id,
	c.customer_name,
	SUM(total_amount) AS total_spend
FROM
	orders o
	LEFT JOIN customers c ON o.customer_id = c.customer_id
GROUP BY
	1, 2  -- same as GROUP BY c.customer_id, c.customer_name
HAVING
	SUM(total_amount) > 100000
ORDER BY
	3 DESC;  -- same as ORDER BY total_spend DESC

-- Q5 Orders without Delivery
-- Write a query to find the orders that were placed but not deliverd
-- Return each resturant name, city and the number of the orders that were not delivered

WITH ranking_table AS (
	SELECT
		r.city,
		r.resturant_name,
		SUM(o.total_amount) AS total_revenue,
		DENSE_RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rnk
	FROM
		orders o
		JOIN restaurants r ON o.resturant_id = r.resturant_id
	WHERE
		o.order_date > CURDATE() - INTERVAL 1 YEAR
	GROUP BY
		r.city,
		r.resturant_name
)
SELECT *
FROM ranking_table
WHERE rnk = 1;

-- Q6 Revenue Ranking
-- Rank resturants by their total revenue from the last year, including their name,
-- total revenue and rank with in their city

WITH ranking_table AS (
	SELECT
		r.city,
		r.resturant_name,
		SUM(o.total_amount) AS total_revenue,
		DENSE_RANK() OVER (
			PARTITION BY r.city 
			ORDER BY SUM(o.total_amount) DESC
		) AS revenue_rank
	FROM
		orders o
		JOIN restaurants r ON o.resturant_id = r.resturant_id
	WHERE
		o.order_date > CURDATE() - INTERVAL 1 YEAR
	GROUP BY
		r.city,
		r.resturant_name
)
SELECT
	city,
	resturant_name,
	total_revenue,
	revenue_rank
FROM
	ranking_table
WHERE
	revenue_rank = 1;


-- Q7 Most Popluar Dish by City
-- Identify the most popluar dish in each city based on the number of the orders.

WITH rank_table AS (
	SELECT
		r.city,
		o.order_item,
		COUNT(o.order_id) AS total_orders,
		RANK() OVER (
			PARTITION BY r.city 
			ORDER BY COUNT(o.order_id) DESC
		) AS dish_rank
	FROM
		orders o
		LEFT JOIN restaurants r ON o.resturant_id = r.resturant_id
	GROUP BY
		r.city,
		o.order_item
)
SELECT
	city,
	order_item AS most_popular_dish,
	total_orders
FROM
	rank_table
WHERE
	dish_rank = 1;

-- Q8 Customer Churn
-- find the orders who havent placed orders in 2024 but in 2023.

SELECT DISTINCT 
    o2023.customer_id,
    c.customer_name
FROM 
    orders o2023
JOIN 
    customers c ON o2023.customer_id = c.customer_id
WHERE 
    YEAR(o2023.order_date) = 2023
    AND o2023.customer_id NOT IN (
        SELECT DISTINCT customer_id 
        FROM orders 
        WHERE YEAR(order_date) = 2024
    )
ORDER BY 
    o2023.customer_id;

-- Q9 Canellation Rate comparrision
-- calcuate and compare the order cancellation rate for each resturant between the current year and
-- the previous year

WITH cancel_ratio_24 AS (
    SELECT
        o.resturant_id,
        ROUND(
            (SUM(CASE WHEN d.delivery_id IS NULL THEN 1 ELSE 0 END) / COUNT(o.order_id)) * 100,
            2
        ) AS cancel_ratio_2024
    FROM orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY o.resturant_id
),
cancel_ratio_23 AS (
    SELECT
        o.resturant_id,
        ROUND(
            (SUM(CASE WHEN d.delivery_id IS NULL THEN 1 ELSE 0 END) / COUNT(o.order_id)) * 100,
            2
        ) AS cancel_ratio_2023
    FROM orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2023
    GROUP BY o.resturant_id
)
SELECT
    r.resturant_id,
    r.resturant_name,
    c24.cancel_ratio_2024,
    c23.cancel_ratio_2023,
    (c24.cancel_ratio_2024 - c23.cancel_ratio_2023) AS rate_change,
    CASE
        WHEN (c24.cancel_ratio_2024 - c23.cancel_ratio_2023) > 5 THEN 'Significantly worse'
        WHEN (c24.cancel_ratio_2024 - c23.cancel_ratio_2023) > 0 THEN 'Slightly worse'
        WHEN (c24.cancel_ratio_2024 - c23.cancel_ratio_2023) < -5 THEN 'Significantly better'
        WHEN (c24.cancel_ratio_2024 - c23.cancel_ratio_2023) < 0 THEN 'Slightly better'
        ELSE 'No change'
    END AS performance_trend
FROM cancel_ratio_24 c24
JOIN cancel_ratio_23 c23 ON c24.resturant_id = c23.resturant_id
JOIN restaurants r ON c24.resturant_id = r.resturant_id
ORDER BY ABS(c24.cancel_ratio_2024 - c23.cancel_ratio_2023) DESC;


SHOW TABLES;


-- Q10 Rider average delivery_time
-- Determine each rider's  average delivery time
WITH average_rider_time AS (
    SELECT
        o.order_id,
        d.rider_id,
        o.order_time,
        d.delivery_time,
        TIMEDIFF(d.delivery_time, o.order_time) AS time_difference,
        ROUND(
            TIME_TO_SEC(
                IF(d.delivery_time < o.order_time,
                   TIMEDIFF(ADDTIME(d.delivery_time, '24:00:00'), o.order_time),
                   TIMEDIFF(d.delivery_time, o.order_time)
                )
            ),
            2
        ) AS time_difference_in_sec,
        ROUND(
            TIME_TO_SEC(
                IF(d.delivery_time < o.order_time,
                   TIMEDIFF(ADDTIME(d.delivery_time, '24:00:00'), o.order_time),
                   TIMEDIFF(d.delivery_time, o.order_time)
                )
            ) / 60,
            2
        ) AS time_difference_in_minutes
    FROM
        orders o
        JOIN deliveries d ON o.order_id = d.order_id
    WHERE
        d.delivery_status = 'Delivered'
)

SELECT
    rider_id,
    ROUND(AVG(time_difference_in_minutes), 2) AS average_delivery_time
FROM
    average_rider_time
GROUP BY
    rider_id;


-- Q11 Monthly Resturant growth Ratio
-- calculate each resturants growth ratio based on the total number of 
-- delivered orders since it's joining


-- Step 1: Aggregate orders per restaurant per month
WITH monthly_orders AS (
    SELECT
        o.resturant_id,
        DATE_FORMAT(o.order_date, '%m-%Y') AS month,
        COUNT(o.order_id) AS order_count
    FROM 
        orders o
    JOIN
        deliveries d ON o.order_id = d.order_id
    WHERE 
        d.delivery_status = 'Delivered'
    GROUP BY 
        o.resturant_id, 
        DATE_FORMAT(o.order_date, '%m-%Y')
),

-- Step 2: Use LAG to get previous month's orders
growth_ratio AS (
    SELECT
        mo.resturant_id,
        r.resturant_name,
        mo.month,
        mo.order_count AS current_month_orders,
        LAG(mo.order_count) OVER (
            PARTITION BY mo.resturant_id 
            ORDER BY STR_TO_DATE(CONCAT('01-', mo.month), '%d-%m-%Y')
        ) AS previous_month_orders
    FROM 
        monthly_orders mo
    LEFT JOIN 
        restaurants r ON mo.resturant_id = r.resturant_id
)

-- Step 3: Calculate growth and trend
SELECT
    resturant_id,
    resturant_name,
    month,
    previous_month_orders,
    current_month_orders,
    ROUND(
        (current_month_orders - COALESCE(previous_month_orders, current_month_orders)) / 
        NULLIF(COALESCE(previous_month_orders, current_month_orders), 0) * 100, 2
    ) AS growth_percentage,
    CASE
        WHEN previous_month_orders IS NULL THEN 'New'
        WHEN (current_month_orders - previous_month_orders) > 0 THEN 'Growing'
        WHEN (current_month_orders - previous_month_orders) < 0 THEN 'Declining'
        ELSE 'Stable'
    END AS trend
FROM 
    growth_ratio
ORDER BY 
    resturant_id,
    STR_TO_DATE(CONCAT('01-', month), '%d-%m-%Y');

-- q12 Customer Segmentation:
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending
-- compared to the average order value(AOV). If a customer's total spending exceeds the AOV,
-- label them as 'Gold';otherwise, label tehm as 'Silver'. write an sql query to determine each segment's'
-- number of orders and total revenue

SELECT
	customer_category,
	SUM(total_orders) AS total_orders,
	SUM(total_spent) AS total_revenue
FROM
	(SELECT
		customer_id,
		SUM(total_amount) AS total_spent,
		COUNT(order_id) AS total_orders,
		CASE
			WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
			WHEN SUM(total_amount) < (SELECT AVG(total_amount) FROM orders) THEN 'Silver'
		END as customer_category
	FROM
		orders
	GROUP BY
		1
) as t1
GROUP BY	
	1;
    
-- Q13 Rider Monthly Earning
-- calculate each rider's total monthly earning, assuming earn 8% of the oder amount

SELECT 
    d.rider_id AS rider_id,
    DATE_FORMAT(o.order_date, '%m-%Y') AS month,
    SUM(o.total_amount) AS total_revenue,
    ROUND(SUM(o.total_amount) * 0.08, 2) AS riders_monthly_earning
FROM 
    orders o
JOIN deliveries d ON o.order_id = d.order_id 
GROUP BY
    d.rider_id,
    month
ORDER BY
    d.rider_id,
    STR_TO_DATE(CONCAT('01-', month), '%d-%m-%Y')
LIMIT 1000;

-- Q14 Rider Rating Analysis
-- find the number of 5-star,Four-star, and 3-star ratings each rider has.
-- riders recive this rating based on delivery time.
--  orders are delivered less than 15 minute of order recived time then rider '5star rating'
-- if they deliver with in15 and 20 minutes they get 4 star rating
-- if they deliver after 20 minute they get 3 star rating

-- Step 1: Create delivery durations and map ratings
WITH riders_rating AS (
    SELECT
        d.order_id,
        d.rider_id,
        o.order_time,
        d.delivery_time,
        ROUND(
            TIME_TO_SEC(
                IF(
                    d.delivery_time < o.order_time,
                    TIMEDIFF(ADDTIME(d.delivery_time, '24:00:00'), o.order_time),
                    TIMEDIFF(d.delivery_time, o.order_time)
                )
            ) / 60, 2
        ) AS delivery_duration
    FROM
        orders o
    JOIN deliveries d ON o.order_id = d.order_id
    WHERE
        d.delivery_status = 'Delivered'
)

-- Step 2: Assign star rating and count them
SELECT
    rider_id,
    rider_rating,
    COUNT(*) AS total_ratings
FROM (
    SELECT
        rider_id,
        delivery_duration,
        CASE
            WHEN delivery_duration < 15 THEN '5 Star'
            WHEN delivery_duration BETWEEN 15 AND 20 THEN '4 Star'
            ELSE '3 Star'
        END AS rider_rating
    FROM riders_rating
) AS rated
GROUP BY
    rider_id,
    rider_rating
ORDER BY
    rider_id,
    rider_rating;
    
-- Q15 Order Frequency by Day;
-- Analyze Order frequency per day of the week and identify the peak day for each resturant

SELECT *  
FROM (  
    SELECT  
        r.resturant_name,  
        DAYNAME(o.order_date) AS day_of_week,  
        COUNT(o.order_id) AS total_orders,  
        RANK() OVER (PARTITION BY r.resturant_name ORDER BY COUNT(o.order_id) DESC) AS day_rank  
    FROM   
        orders o  
    JOIN restaurants r ON o.resturant_id = r.resturant_id  
    GROUP BY  
        r.resturant_name,  
        DAYNAME(o.order_date)  
) AS ranked_orders  
WHERE day_rank = 1  
ORDER BY resturant_name;


-- Q16 Customer life time value
-- calculate the total revenue generated by the each customers on all the orders

SELECT
	o.customer_id,
	c.customer_name,
	count(o.order_item) as total_items,
	sum(o.total_amount) as CLV
FROM
	orders o
	JOIN deliveries d ON o.order_id = d.order_id
	JOIN customers c ON o.customer_id = c.customer_id
	where 	d.delivery_status = 'Delivered'
GROUP BY
	1,
	2
ORDER BY
	3 DESC;
    
-- Q17 Monthly Sales trend
-- Identify sales trends by comparing each months total sales to the previous month.
SELECT 
	EXTRACT(YEAR FROM order_date) as year,
	EXTRACT(month FROM order_date) as month,
	sum(total_amount) as current_month_total_amount,
	LAG(SUM(total_amount),1) OVER (ORDER BY EXTRACT(YEAR FROM order_date),EXTRACT(MONTH FROM order_date))
	as previous_month_total_amount
FROM orders
group by
	1,2;
-- Q18 Rider Efficieny
-- Determine the rider efficieny by determing average delivery times and identifying those have highest and lowest averages

WITH rider_efficiency AS (
    SELECT
        d.rider_id AS riders_id,
        ROUND(
            TIME_TO_SEC(
                IF(
                    d.delivery_time < o.order_time,
                    TIMEDIFF(ADDTIME(d.delivery_time, '24:00:00'), o.order_time),
                    TIMEDIFF(d.delivery_time, o.order_time)
                )
            ) / 60,
            2
        ) AS time_duration
    FROM 
        orders o
    JOIN deliveries d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),
riders_time AS (
    SELECT 
        riders_id,
        ROUND(AVG(time_duration), 2) AS avg_time
    FROM rider_efficiency
    GROUP BY riders_id
)
SELECT
    MIN(avg_time) AS rider_minimum_average_time,
    MAX(avg_time) AS rider_maximum_average_time
FROM riders_time;

-- Q19 Order Item Popularity
-- Track the popularity of specific order items over a time and identify seasonal demand spikes

WITH order_item_popularity AS (
    SELECT
        order_item,
        MONTH(order_date) AS month,
        CASE
            WHEN MONTH(order_date) BETWEEN 4 AND 6 THEN 'Spring'
            WHEN MONTH(order_date) BETWEEN 7 AND 8 THEN 'Summer'
            ELSE 'Winter'
        END AS season
    FROM orders
)
SELECT
    order_item,
    season,
    COUNT(*) AS total_orders
FROM order_item_popularity
GROUP BY
    order_item,
    season
ORDER BY
    order_item,
    total_orders DESC;


-- Q20: Rank each city based on the total revenue for the previous year 2023
SELECT
    r.city,
    SUM(o.total_amount) AS revenue,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS city_rank
FROM
    orders o
JOIN restaurants r ON o.resturant_id = r.resturant_id
GROUP BY
    r.city
ORDER BY
    city_rank;
-- Q21: Top 3 Cities by Average Order Value (AOV)
-- Find the top 3 cities where the average order value is the highest in the last 1 year.
SELECT 
    r.city,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM 
    orders o
JOIN 
    restaurants r ON o.resturant_id = r.resturant_id
WHERE 
    o.order_date >= CURDATE() - INTERVAL 1 YEAR
GROUP BY 
    r.city
ORDER BY 
    avg_order_value DESC
LIMIT 3;


-- Q22: Customer Retention Rate (2023 to 2024)
-- Calculate the percentage of customers who placed orders in 2023 and also placed orders in 2024.

WITH customers_2023 AS (
    SELECT DISTINCT customer_id FROM orders WHERE YEAR(order_date) = 2023
),
customers_2024 AS (
    SELECT DISTINCT customer_id FROM orders WHERE YEAR(order_date) = 2024
)
SELECT
    ROUND(
        (SELECT COUNT(*) FROM customers_2023 c23 WHERE c23.customer_id IN (SELECT customer_id FROM customers_2024)) 
        / (SELECT COUNT(*) FROM customers_2023) * 100, 2
    ) AS retention_rate_percent;

-- Q23: Peak Delivery Hours (By Rider)
-- For each rider, find the 2-hour time slot during which they deliver the most orders.

SELECT
    rider_id,
    time_slot,
    MAX(order_count) AS max_deliveries
FROM (
    SELECT
        d.rider_id,
        CASE
            WHEN HOUR(o.order_time) BETWEEN 0 AND 1 THEN '00:00-02:00'
            WHEN HOUR(o.order_time) BETWEEN 2 AND 3 THEN '02:00-04:00'
            WHEN HOUR(o.order_time) BETWEEN 4 AND 5 THEN '04:00-06:00'
            WHEN HOUR(o.order_time) BETWEEN 6 AND 7 THEN '06:00-08:00'
            WHEN HOUR(o.order_time) BETWEEN 8 AND 9 THEN '08:00-10:00'
            WHEN HOUR(o.order_time) BETWEEN 10 AND 11 THEN '10:00-12:00'
            WHEN HOUR(o.order_time) BETWEEN 12 AND 13 THEN '12:00-14:00'
            WHEN HOUR(o.order_time) BETWEEN 14 AND 15 THEN '14:00-16:00'
            WHEN HOUR(o.order_time) BETWEEN 16 AND 17 THEN '16:00-18:00'
            WHEN HOUR(o.order_time) BETWEEN 18 AND 19 THEN '18:00-20:00'
            WHEN HOUR(o.order_time) BETWEEN 20 AND 21 THEN '20:00-22:00'
            WHEN HOUR(o.order_time) BETWEEN 22 AND 23 THEN '22:00-00:00'
        END AS time_slot,
        COUNT(o.order_id) AS order_count
    FROM orders o
    JOIN deliveries d ON o.order_id = d.order_id
    GROUP BY d.rider_id, time_slot
) AS sub
GROUP BY rider_id, time_slot
ORDER BY rider_id, max_deliveries DESC;

-- Q24: Resturants with Highest Cancellation Rate (Last 6 Months)
-- List the top 5 restaurants with the highest cancellation rates in the last 6 months.


WITH recent_orders AS (
    SELECT 
        o.resturant_id,
        o.order_id,
        CASE WHEN d.delivery_id IS NULL THEN 1 ELSE 0 END AS is_cancelled
    FROM 
        orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE 
        o.order_date >= CURDATE() - INTERVAL 6 MONTH
)
SELECT 
    r.resturant_name,
    ROUND(SUM(ro.is_cancelled) / COUNT(ro.order_id) * 100, 2) AS cancellation_rate_percent
FROM 
    recent_orders ro
JOIN restaurants r ON ro.resturant_id = r.resturant_id
GROUP BY 
    ro.resturant_id
ORDER BY 
    cancellation_rate_percent DESC
LIMIT 5;


-- Q25: Customers with Increasing Order Frequency
-- Identify customers whose number of orders in the last 6 months has increased compared to the previous 6 months.

WITH orders_last_6_months AS (
    SELECT customer_id, COUNT(*) AS orders_6m
    FROM orders
    WHERE order_date >= CURDATE() - INTERVAL 6 MONTH
    GROUP BY customer_id
),
orders_prev_6_months AS (
    SELECT customer_id, COUNT(*) AS orders_prev_6m
    FROM orders
    WHERE order_date >= CURDATE() - INTERVAL 12 MONTH
      AND order_date < CURDATE() - INTERVAL 6 MONTH
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.customer_name,
    COALESCE(o6.orders_6m, 0) AS orders_last_6_months,
    COALESCE(op6.orders_prev_6m, 0) AS orders_prev_6_months
FROM
    customers c
LEFT JOIN orders_last_6_months o6 ON c.customer_id = o6.customer_id
LEFT JOIN orders_prev_6_months op6 ON c.customer_id = op6.customer_id
WHERE
    COALESCE(o6.orders_6m, 0) > COALESCE(op6.orders_prev_6m, 0)
ORDER BY
    orders_last_6_months DESC;


-- end of report -- 