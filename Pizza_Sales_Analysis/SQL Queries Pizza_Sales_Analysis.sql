create database Pizza_Sales_Project;
use Pizza_Sales_Project;

select * from orders;
select * from order_details;
select * from pizza_types;
select * from pizzas;


#>> BASIC KPIs 
#>> Total Revenue
#>> 1. What is the total revenue generated?

SELECT 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id;


#>> Total Orders
#>> 2. How many total orders were placed?

SELECT 
    COUNT(DISTINCT order_id) AS total_orders
FROM orders;



#>> Total Pizzas Sold
#>> 3. How many pizzas were sold in total?


SELECT 
    SUM(quantity) AS total_pizzas_sold
FROM order_details;




#>> Average Order Value (AOV)
#>> 4. What is the average revenue per order?

SELECT 
    ROUND(SUM(od.quantity * p.price) / COUNT(DISTINCT od.order_id), 2) AS avg_order_value
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id;









#>> Average Pizzas per Order
#>> 5. On average, how many pizzas are ordered per order?

SELECT 
    ROUND(SUM(quantity) / COUNT(DISTINCT order_id), 2) AS avg_pizzas_per_order
FROM order_details;


#>> Revenue per Pizza (Avg)
#>> 6. What is the average revenue per pizza sold?

SELECT 
    ROUND(SUM(od.quantity * p.price) / SUM(od.quantity), 2) AS avg_revenue_per_pizza
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id;


#>> Orders by Date
#>> 7.How many orders are placed each day?

SELECT 
    order_date,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_date
ORDER BY order_date;


#>> Revenue by Date
#>> 8. How does revenue trend over time?


SELECT 
    o.order_date,
    ROUND(SUM(od.quantity * p.price), 2) AS daily_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY o.order_date
ORDER BY o.order_date;








#>> Orders by Hour
#>> 9. At what time of day are most orders placed?

SELECT 
    HOUR(order_time) AS order_hour,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY order_hour;

#>> Revenue by Hour
#>> 10. Which time slots generate the highest revenue?

SELECT 
    HOUR(o.order_time) AS order_hour,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY order_hour
ORDER BY revenue DESC;







#>> Orders by Day of Week
#>> 11. Which days have the highest order volume?

SELECT 
    DAYNAME(order_date) AS day_name,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY day_name;









#>> Revenue by Day of Week
#>> 12. Which days generate the most revenue?


SELECT 
    DAYNAME(o.order_date) AS day_name,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY day_name
ORDER BY revenue DESC;







#>> Revenue by Pizza Category
#>> 13. Which category contributes the most revenue?
SELECT 
    pt.category,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY revenue DESC;











#>> Quantity Sold by Category
#>> 14. Which category sells the most pizzas?
SELECT 
    pt.category,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category;










#>> Revenue by Pizza Size
#>> 15. Which pizza size generates maximum revenue?
SELECT 
    p.size,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY revenue DESC;


#>> Quantity Sold by Size
#>> 16. Which pizza size is most preferred by customers?

SELECT 
    p.size,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size;









#>> Category Contribution %
#>> 17. What % of total revenue comes from each category?

SELECT 
    pt.category,
    ROUND(
        SUM(od.quantity * p.price) * 100.0 /
        (SELECT SUM(od.quantity * p.price)
         FROM order_details od
         JOIN pizzas p ON od.pizza_id = p.pizza_id), 2
    ) AS revenue_percentage
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category;










#>> Size Contribution %
#>> 18. What % of revenue comes from each pizza size?
SELECT 
    p.size,
    ROUND(
        SUM(od.quantity * p.price) * 100.0 /
        (SELECT SUM(od.quantity * p.price)
         FROM order_details od
         JOIN pizzas p ON od.pizza_id = p.pizza_id), 2
    ) AS revenue_percentage
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size;











#>> Top 5 Pizzas by Revenue
#>> 19. Which pizzas generate the highest revenue?
SELECT 
    pt.name,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 5;









#>> Top 5 Pizzas by Quantity
#>> 20.Which pizzas are ordered the most?

SELECT 
    pt.name,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;









#>> Bottom 5 Pizzas by Revenue
#>> 21. Which pizzas underperform in revenue?

SELECT 
    pt.name,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue ASC
LIMIT 5;










#>> Bottom 5 Pizzas by Quantity
#>> 22. Which pizzas sell the least?

SELECT 
    pt.name,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity ASC
LIMIT 5;









#>> Revenue per Pizza Type
#>> 23. How much revenue does each pizza generate?

SELECT 
    pt.name,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name;









#>> Orders per Pizza Type
#>> 24. How frequently is each pizza ordered?
SELECT 
    pt.name,
    COUNT(DISTINCT od.order_id) AS total_orders
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name;









#>> Top 10 Revenue-Contributing Pizzas (%)
#>> 25. Which pizzas contribute most to total revenue?

SELECT 
    pt.name,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue,
    RANK() OVER (ORDER BY SUM(od.quantity * p.price) DESC) AS revenue_rank
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name;










#>> Cumulative Revenue Contribution
#>> 26. Do few pizzas drive most revenue (Pareto)?
SELECT 
    pt.category,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue,
    RANK() OVER (ORDER BY SUM(od.quantity * p.price) DESC) AS category_rank
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category;









#>> Cumulative Revenue Contribution
#>> 27. Do few pizzas drive most revenue (Pareto)?
SELECT 
    pt.name,
    ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 10;









#>> Rank Categories by Revenue
#>> 28. Which categories perform best overall?
SELECT 
    od.order_id,
    ROUND(SUM(od.quantity * p.price), 2) AS order_value
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY od.order_id
HAVING order_value > (
    SELECT 
        SUM(od.quantity * p.price) / COUNT(DISTINCT od.order_id)
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
);









#>> High-Value Orders
#>> 29. Which orders generate above-average revenue?
SELECT 
    pt.category,
    SUM(od.quantity) AS total_quantity
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
WHERE HOUR(o.order_time) BETWEEN 18 AND 21
GROUP BY pt.category
ORDER BY total_quantity DESC;








#>> Peak Hour Category Preference
#>> 30. Which category sells most during peak hours?

SELECT 
    MONTH(o.order_date) AS month,
    ROUND(SUM(od.quantity * p.price), 2) AS monthly_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY month
ORDER BY month;




