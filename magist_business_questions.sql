use magist123;
select * from customers;
select * from geo;
select * from order_items;
select * from order_payments;
select * from order_reviews;
select * from orders;
select * from product_category_name_translation;
select * from products;
select * from sellers;

select database();

-- How many orders are there in the dataset? The orders table contains a row for each order, so this should be easy to find out!

SELECT 
    COUNT(order_id)
FROM
    orders;

-- Are orders actually delivered? Look at the columns in the orders table: one of them is called order_status. 
-- Most orders seem to be delivered, but some aren’t. Find out how many orders are delivered and how many are cancelled, unavailable, or in any other status by grouping and aggregating this column.
select distinct order_status from orders;

SELECT 
    order_status, COUNT(order_id)
FROM
    orders
GROUP BY order_status;

-- Is Magist having user growth? A platform losing users left and right isn’t going to be very useful to us. 
-- It would be a good idea to check for the number of orders grouped by year and month. 
-- Tip: you can use the functions YEAR() and MONTH() to separate the year and the month of the order_purchase_timestamp.

SELECT 
    YEAR(order_purchase_timestamp) AS year,
    MONTH(order_purchase_timestamp),
    COUNT(order_id)
FROM
    orders
GROUP BY YEAR(order_purchase_timestamp) , MONTH(order_purchase_timestamp)
ORDER BY YEAR(order_purchase_timestamp) , MONTH(order_purchase_timestamp);

-- How many products are there on the products table? (Make sure that there are no duplicate products.)
select database();

SELECT 
    COUNT(DISTINCT (product_id))
FROM
    products;
    
-- Which are the categories with the most products? Since this is an external database and has been partially anonymized, we do not have the names of the products. 
-- But we do know which categories products belong to. This is the closest we can get to knowing what sellers are offering in the Magist marketplace. 
-- By counting the rows in the products table and grouping them by categories, we will know how many products are offered in each category. 
-- This is not the same as how many products are actually sold by category. To acquire this insight we will have to combine multiple tables together: we’ll do this in the next lesson.

SELECT 
    pro.product_category_name AS category_name,
    proTrans.product_category_name_english AS English_Translation,
    COUNT(distinct(pro.product_id)) AS total_products
FROM
    products pro
        JOIN
    product_category_name_translation proTrans ON pro.product_category_name = proTrans.product_category_name
GROUP BY pro.product_category_name
order by total_products desc;

-- How many of those products were present in actual transactions? 
-- The products table is a “reference” of all the available products. Have all these products been involved in orders? Check out the order_items table to find out!

select count(product_id) from products;

SELECT 
    COUNT(DISTINCT (product_id))
FROM
    order_items;
    
-- What’s the price for the most expensive and cheapest products?
-- Sometimes, having a broad range of prices is informative.Looking for the maximum and minimum values is also a good way to detect extreme outliers

SELECT 
    MIN(price), MAX(price)
FROM
    order_items;
    
-- What are the highest and lowest payment values? Some orders contain multiple products. 
-- What’s the highest someone has paid for an order? Look at the order_payments table and try to find it out.

SELECT 
    MAX(payment_value), MIN(payment_value)
FROM
    order_payments;

SELECT 
    *
FROM
    order_payments
ORDER BY payment_value DESC;

SELECT 
    SUM(payment_value) AS Highest_order
FROM
    order_payments
GROUP BY order_id
ORDER BY highest_order DESC
LIMIT 5;






-- Business questions

-- section 3

--  **Average Delivery Time by Product Category:**
-- What’s the average time between the order being placed and the product being delivered?

-- Avg price based on category
SELECT 
    p.product_category_name AS product_category,
    pt.product_category_name_english AS product_category_english,
    AVG(DATEDIFF(o.order_delivered_customer_date,
            o.order_approved_at)) AS avg_delivery_days
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pt ON p.product_category_name = pt.product_category_name
WHERE
    o.order_delivered_customer_date IS NOT NULL
GROUP BY p.product_category_name , pt.product_category_name_english
ORDER BY avg_delivery_days DESC;

-- Avg price by tech-products
SELECT 
    p.product_category_name AS product_category,
    pt.product_category_name_english AS product_category_english,
    AVG(DATEDIFF(o.order_delivered_customer_date,
            o.order_approved_at)) AS avg_delivery_days
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pt ON p.product_category_name = pt.product_category_name
WHERE
    o.order_delivered_customer_date IS NOT NULL
GROUP BY p.product_category_name , pt.product_category_name_english
HAVING p.product_category_name IN ('audio',
 'eletronicos',
 'informatica_acessorios',
 'pc_gamer',
 'pcs',
 'tablets_impressao_imagem',
 'telefonia')
ORDER BY avg_delivery_days DESC;

-- Avg price of overall products
select avg(datediff(order_delivered_customer_date,order_purchase_timestamp)) from orders;


-- How many orders are delivered on time vs orders delivered with a delay?

SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        ELSE 'Delayed'
    END AS delivery_status,
    COUNT(distinct(order_id)) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

-- Is there any pattern for delayed orders, e.g. big products being delayed more often?

select * from products;
select * from order_items;

-- total delayed tech products

SELECT 
    COUNT(*) AS total_delayed_orders
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
WHERE
    o.order_delivered_customer_date > order_estimated_delivery_date
        AND p.product_category_name IN ('audio',
 'eletronicos',
 'informatica_acessorios',
 'pc_gamer',
 'pcs',
 'tablets_impressao_imagem',
 'telefonia');
    
-- delayed products in each tech categories
SELECT 
    p.product_category_name, COUNT(*) AS total_delayed_orders
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
WHERE
    o.order_delivered_customer_date > order_estimated_delivery_date
GROUP BY p.product_category_name
HAVING p.product_category_name IN ('audio',
 'eletronicos',
 'informatica_acessorios',
 'pc_gamer',
 'pcs',
 'tablets_impressao_imagem',
 'telefonia')
ORDER BY total_delayed_orders DESC;

  -- section  2    
-- total sellers by cities

SELECT 
    g.city, COUNT(s.seller_id) AS total_seller_cities
FROM
    geo g
        JOIN
    sellers s ON s.seller_zip_code_prefix = g.zip_code_prefix
GROUP BY city
ORDER BY total_seller_cities DESC;


-- How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?

select count(distinct(seller_id)) from sellers s join order_items oi on s.seller_id = oi.seller_id;
select * from order_items;


-- section 1

SELECT 
    COUNT(*)
FROM
    products
WHERE
    product_category_name IN ('audio',
 'eletronicos',
 'informatica_acessorios',
 'pc_gamer',
 'pcs',
 'tablets_impressao_imagem',
 'telefonia');
 
 
-- What categories of tech products does Magist have?

SELECT 
    pro.product_category_name AS category_name,
    proTrans.product_category_name_english AS English_Translation,
    COUNT(DISTINCT (pro.product_id)) AS total_products
FROM
    products pro
        JOIN
    product_category_name_translation proTrans ON pro.product_category_name = proTrans.product_category_name
GROUP BY pro.product_category_name
HAVING pro.product_category_name IN ('audio',
 'eletronicos',
 'informatica_acessorios',
 'pc_gamer',
 'pcs',
 'tablets_impressao_imagem',
 'telefonia')
ORDER BY total_products DESC;

-- percentage of tech products 

SELECT 
    COUNT(CASE
        WHEN
            product_category_name IN ('audio',
 'eletronicos',
 'informatica_acessorios',
 'pc_gamer',
 'pcs',
 'tablets_impressao_imagem',
 'telefonia')
        THEN
            1
    END) AS tech_products,
    COUNT(*) AS total_products,
    ROUND(COUNT(CASE
                WHEN
                    product_category_name IN ('audio',
 'eletronicos',
 'informatica_acessorios',
 'pc_gamer',
 'pcs',
 'tablets_impressao_imagem',
 'telefonia')
                THEN
                    1
            END) * 100.0 / COUNT(*),
            2) AS tech_percentage
FROM
    products;

-- Average price of products being sold

SELECT 
    AVG(price)
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
WHERE
    p.product_category_name IN ('audio',
 'eletronicos',
 'informatica_acessorios',
 'pc_gamer',
 'pcs',
 'tablets_impressao_imagem',
 'telefonia');
        
	-- Are expensive tech products popular? *
    
SELECT 
    CASE
        WHEN oi.price > 500 THEN 'Expensive'
        ELSE 'Not Expensive'
    END AS price_category,
    COUNT(oi.order_id) AS total_orders
FROM
    products p
        JOIN
    order_items oi ON p.product_id = oi.product_id
WHERE
    p.product_category_name IN ('audio' , 'eletronicos',
        'informatica_acessorios',
        'pc_gamer',
        'pcs',
        'tablets_impressao_imagem',
        'telefonia')
GROUP BY price_category;

SELECT 
    AVG(orre.review_score)
FROM
    order_reviews orre
        JOIN
    order_items oi ON orre.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
HAVING p.product_category_name IN ('audio' , 'eletronicos',
    'informatica_acessorios',
    'pc_gamer',
    'pcs',
    'tablets_impressao_imagem',
    'telefonia');
    
    -- customers based on city
SELECT 
    g.city, COUNT(*)
FROM
    customers c
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
GROUP BY g.city;

-- customers makes order with tech-products

SELECT 
    c.customer_id,
    COUNT(o.order_id)
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
    where p.product_category_name in ('audio' , 'eletronicos',
    'informatica_acessorios',
    'pc_gamer',
    'pcs',
    'tablets_impressao_imagem',
    'telefonia')
	GROUP BY o.customer_id;
    
    -- top 10 customer by spending
    
   SELECT 
    c.customer_id,
    c.customer_unique_id,
    g.city,
    g.state,
    SUM(op.payment_value) AS total_spending
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
        JOIN
    order_payments op ON o.order_id = op.order_id 
GROUP BY c.customer_id , c.customer_unique_id , g.city , g.state
ORDER BY total_spending DESC
LIMIT 10;
    
    
-- checking whether the top 10 customers bought tech-products
    
    SELECT 
    t.customer_id,
    t.customer_unique_id,
    t.city,
    t.state,
    t.total_spending,
    CASE 
        WHEN SUM(CASE WHEN p.product_category_name IN (
            'electronics',
            'computers_accessories',
            'telephony',
            'computers',
            'audio',
            'pc_gamer'
        ) THEN 1 ELSE 0 END) > 0 
        THEN 'Yes' ELSE 'No'
    END AS bought_tech_products
FROM (
    -- top 10 query
    SELECT 
        c.customer_id,
        c.customer_unique_id,
        g.city,
        g.state,
        SUM(op.payment_value) AS total_spending
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
    JOIN order_payments op ON o.order_id = op.order_id 
    GROUP BY c.customer_id, c.customer_unique_id, g.city, g.state
    ORDER BY total_spending DESC
    LIMIT 10
) t
JOIN orders o ON t.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY t.customer_id, t.customer_unique_id, t.city, t.state, t.total_spending
ORDER BY t.total_spending DESC;
    
-- repeat customers

SELECT c.customer_unique_id,
          COUNT(DISTINCT o.order_id) AS repeat_purchase_count
      FROM customers c
      JOIN orders o ON c.customer_id = o.customer_id
      GROUP BY c.customer_unique_id
      HAVING COUNT(DISTINCT o.order_id) > 1
      ORDER BY repeat_purchase_count DESC;
      
-- top 5 products from review score

      SELECT p.product_id,
          p.product_category_name AS product_category,
          AVG(r.review_score) AS avg_review_score
      FROM products p
      JOIN order_items oi ON p.product_id = oi.product_id
      JOIN order_reviews r ON oi.order_id = r.order_id
      GROUP BY p.product_id, p.product_category_name
      ORDER BY avg_review_score DESC
      LIMIT 5;
    
    -- monthly sales and revenue growth
    
      SELECT YEAR(o.order_purchase_timestamp) AS year_,
          -- MONTH(o.order_purchase_timestamp) AS month_,
          COUNT(DISTINCT o.order_id) AS monthly_orders,
          round(SUM(op.payment_value),2) AS monthly_revenue
      FROM orders o join order_payments op on o.order_id = op.order_id
      GROUP BY year_
      ORDER BY year_;
      
      
      
      SELECT 
    YEAR(o.order_purchase_timestamp) AS year_,
    -- MONTH(o.order_purchase_timestamp) AS month_,
    COUNT(DISTINCT o.order_id) AS monthly_tech_orders,
    round(SUM(op.payment_value),2) AS monthly_tech_revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
    join order_payments op on o.order_id = op.order_id
WHERE p.product_category_name IN (
    'electronics',
    'computers_accessories',
    'telephony',
    'computers',
    'audio',
    'pc_gamer'
) -- adjust to your tech categories
GROUP BY year_
ORDER BY year_;

    
    select * from order_items;
    select * from products;

