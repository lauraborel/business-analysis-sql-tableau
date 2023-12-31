Use magist; 
SELECT * 
FROM order_items; 

SELECT * 
FROM order_items 
ORDER BY shipping_limit_date; 

-- CHALLENGE 1 ON WINDOW FUNCTIONS:  -- 
/* 
Select all orders with their corresponding products in order_items. 
We want only the orders with a shipping_limit_date before midnight 2016-10-09. 
Add a column called total_order_price with a sum of the price of all products belonging to the same order. 
And add another column showing how many products were in each order. 
*/ 

SELECT 
order_id, 
product_id,
price AS product_price, 
SUM(ROUND((price), 2))  OVER (PARTITION BY order_id ) AS total_order_price,
COUNT(order_id) OVER (PARTITION BY order_id) AS no_of_products
FROM order_items 
WHERE shipping_limit_date  < '2016-10-09 00:00:00'; 

-- CHALLENGE 2 ON WINDWO FUNCTIONS: -- 
/* We want to see how much people spent in a particular category on a specific day. Select purchased items from order_items that meet these conditions:
    - Their order_purchase_timestamp date is 2016-10-09
    - Their order_status is “delivered”
    - To which category does this product belong? –> English category name, not Portuguese
    - Add a column called avg_category_payment with the average price of the items belonging to the same category.
    - Add a column called category_total_sales with the summation of the prices for products belonging to the category
    - Order the rows by category_total_sales, so we can see which category has made the largest sales on 2016-10-09
*/ 

SELECT 
oi.product_id, 
pcnt.product_category_name_english AS category_english, 
AVG(ROUND(oi.price, 2)) OVER (PARTITION BY pcnt.product_category_name_english) AS avg_category_payment, 
oi.price AS product_price, 
SUM(ROUND(oi.price, 2)) OVER (PARTITION BY pcnt.product_category_name_english) AS category_total_sales
FROM order_items oi
JOIN orders o
ON oi.order_id = o.order_id
JOIN products p
ON oi.product_id = p.product_id
JOIN product_category_name_translation pcnt
ON p.product_category_name = pcnt.product_category_name
WHERE DATE(o.order_purchase_timestamp) = "2016-10-09 " and o.order_status = "delivered"
ORDER BY category_total_sales DESC; 






-- CHALLENGE ON SQL SUBQUEWEIES AND TEMPORARY TABLES -- 
/* 
 Select all the products from the health_beauty or perfumery categories that
have been paid by credit card with a payment amount of more than 1000$,
from orders that were purchased during 2018 and have a ‘delivered’ status?

For the products that you selected, get the following information:
        1. The average weight of those products
        2. The cities where there are sellers that sell those products
        3. The cities where there are customers who bought products
*/ 

# 1. get average weight
SELECT 
    AVG(product_weight_g)
FROM
    (SELECT 
        products.product_weight_g,
            products.product_id,
            product_category_name_english,
            order_payments.payment_value,
            orders.order_purchase_timestamp,
            orders.order_status
    FROM
        products
    JOIN product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
    JOIN order_items ON products.product_id = order_items.product_id
    JOIN order_payments ON order_payments.order_id = order_items.order_id
    JOIN orders ON order_payments.order_id = orders.order_id
    WHERE
        (order_payments.payment_type = 'credit_card'
            AND order_payments.payment_value > 1000
            AND YEAR(orders.order_purchase_timestamp) = 2018
            AND orders.order_status = 'delivered'
            AND (product_category_name_english LIKE 'health_beauty'
            OR product_category_name_english LIKE 'perfumery'))) AS sub; 
    
# 2. get cities of sellers 
SELECT DISTINCT
    seller_zip_code_prefix
FROM
    sellers
        JOIN
    order_items ON sellers.seller_id = order_items.seller_id
        JOIN
    products ON order_items.product_id = products.product_id
        JOIN
    product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
        JOIN
    order_payments ON order_payments.order_id = order_items.order_id
        JOIN
    orders ON order_payments.order_id = orders.order_id
WHERE
    (order_payments.payment_type = 'credit_card'
        AND order_payments.payment_value > 1000
        AND YEAR(orders.order_purchase_timestamp) = 2018
        AND orders.order_status = 'delivered'
        AND (product_category_name_english LIKE 'health_beauty'
        OR product_category_name_english LIKE 'perfumery')); 

#  3. get cities of customers 
SELECT DISTINCT
    customer_zip_code_prefix
FROM
    customers
        JOIN
    orders ON customers.customer_id = orders.customer_id
        JOIN
    order_items ON order_items.order_id = orders.order_id
        JOIN
    products ON order_items.product_id = products.product_id
        JOIN
    product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
        JOIN
    order_payments ON order_payments.order_id = order_items.order_id
WHERE
    (order_payments.payment_type = 'credit_card'
        AND order_payments.payment_value > 1000
        AND YEAR(orders.order_purchase_timestamp) = 2018
        AND orders.order_status = 'delivered'
        AND (product_category_name_english LIKE 'health_beauty'
        OR product_category_name_english LIKE 'perfumery')); 


/* ------------------- Solution with temporary table ----------------------------------- */ 
drop table if exists my_products;

CREATE TEMPORARY TABLE my_products
SELECT orders.customer_id, order_items.seller_id, products.product_weight_g, products.product_id, product_category_name_english, order_payments.payment_value, orders.order_purchase_timestamp, orders.order_status
FROM products
JOIN product_category_name_translation
ON products.product_category_name = product_category_name_translation.product_category_name
JOIN order_items
ON products.product_id = order_items.product_id
JOIN order_payments
ON order_payments.order_id = order_items.order_id
JOIN orders
ON order_payments.order_id = orders.order_id
WHERE (
	order_payments.payment_type = "credit_card" 
	AND order_payments.payment_value >	1000
    AND YEAR(orders.order_purchase_timestamp) = 2018
    AND orders.order_status = "delivered" 
    AND (product_category_name_english LIKE "health_beauty" OR product_category_name_english LIKE "perfumery")
    ) 
    ; 
    
# get sellers cities solution 
SELECT DISTINCT
    seller_zip_code_prefix
FROM
    sellers
        RIGHT JOIN
    my_products ON my_products.seller_id = sellers.seller_id; 

# get customer cities solution 
SELECT DISTINCT
    customer_zip_code_prefix
FROM
    customers
        RIGHT JOIN
    my_products ON my_products.customer_id = customers.customer_id; 





-- CHALLENGES ON SQL STORED ROUTINES-- 

# define function 1 
DELIMITER $$ 
CREATE FUNCTION delay_range (
     actual DATETIME,
     estimated DATETIME
)
RETURNS VARCHAR(200)
 
DETERMINISTIC
 
BEGIN 
DECLARE result_var VARCHAR(200);
	 IF DATEDIFF(estimated, actual) > 0 AND DATEDIFF(estimated, actual) < 2  THEN
		SET result_var = '1 day';
	ELSEIF DATEDIFF(estimated, actual) > 1 AND DATEDIFF(estimated, actual) <=3  THEN
		SET result_var = '2-3 days';
	ELSEIF DATEDIFF(estimated, actual) > 3 AND DATEDIFF(estimated, actual) <= 7  THEN
		SET result_var = '4-7 days';
    ELSEIF DATEDIFF(estimated, actual) > 7 AND DATEDIFF(estimated, actual) <= 14  THEN
		SET result_var = 'more than a week to two weeks';
	ELSEIF DATEDIFF(estimated, actual) > 14 AND DATEDIFF(estimated, actual) <= 100 THEN
		SET result_var = 'more than two weeks';
	ELSEIF DATEDIFF(estimated, actual) > 100  THEN
		SET result_var = 'more than 100 days';
	ELSEIF DATEDIFF(estimated, actual) = 0  THEN
		SET result_var = 'no delay';
	ELSE 
		SET result_var = "some_mistake here"; 
	END IF; 
RETURN (result_var);  
END$$ 

DELIMITER ;

# define function 2: 

DELIMITER $$
 
CREATE FUNCTION on_time(
     actual DATETIME,
     estimated DATETIME
)
RETURNS VARCHAR(10)
 
DETERMINISTIC
 
BEGIN
DECLARE result_var VARCHAR(10);
     IF TIMESTAMPDIFF(DAY, actual, estimated) >= 0 THEN
          SET result_var = 'On time';
     ELSE
		SET result_var = 'Late';
     END IF;
RETURN (result_var);
END$$
 
DELIMITER ;

# apply functions
SELECT
     order_id,
     delay_range(order_delivered_customer_date, order_estimated_delivery_date) AS delay_range
FROM orders
WHERE order_status like 'delivered';

SELECT
delay_range(order_delivered_customer_date, order_estimated_delivery_date) AS delay_range,
AVG(price), 
AVG(product_weight_g) AS weight_avg,
MAX(product_weight_g) AS max_weight,
MIN(product_weight_g) AS min_weight,
SUM(product_weight_g) AS sum_weight,
AVG(product_weight_g*product_length_cm*product_width_cm) AS volume_avg,
SUM(product_weight_g*product_length_cm*product_width_cm) AS volume_sum,
MAX(product_weight_g*product_length_cm*product_width_cm) AS volume_max,
COUNT(*) AS product_count 
FROM orders a
LEFT JOIN order_items b
	ON a.order_id = b.order_id
LEFT JOIN products c
	ON b.product_id = c.product_id
LEFT JOIN product_category_name_translation
	ON c.product_category_name = product_category_name_translation.product_category_name
WHERE product_category_name_translation.product_category_name_english IN 
("audio", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image", "telephony")
GROUP BY delay_range 
ORDER BY product_count DESC; 

# Define a procedure
DELIMITER $$
CREATE PROCEDURE `sold_tech_products` ()
BEGIN
SELECT product_category_name_english AS transl, 
COUNT(order_items.product_id) AS sold_products
FROM product_category_name_translation AS tabletransl
LEFT JOIN products ON tabletransl.product_category_name = products.product_category_name
LEFT JOIN  order_items
ON products.product_id = order_items.product_id
WHERE product_category_name_english IN ("audio", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image", "telephony")
GROUP BY product_category_name_english
ORDER BY COUNT(order_items.order_item_id) DESC;  
END$$ 
DELIMITER ;

# Call the procedure 	
CALL sold_tech_products;

# Make another procedure for the most sold products by income
DELIMITER $$
CREATE PROCEDURE `sold_tech_products_by_price` ()
BEGIN
SELECT 
    SUM(order_items.price) AS sold_products_income,
    tabletransl.product_category_name_english
FROM
    product_category_name_translation AS tabletransl
        LEFT JOIN
    products ON tabletransl.product_category_name = products.product_category_name
        LEFT JOIN
    order_items ON products.product_id = order_items.product_id
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers_accessories',
        'pc_gamer',
        'computers',
        'tablets_printing_image',
        'telephony')
GROUP BY product_category_name_english
ORDER BY sold_products_income DESC;  
END$$ 
DELIMITER 

CALL sold_tech_products_by_price;






-- FINAL SQL CHALLENGE FOR INTERVIEW PREPARATION -- 

/* 
---------------------------- PART 1: EXPAND THE DATABASE -----------------------------------------------------
*/ 
-- 1. Find online a dataset that contains the abbreviations for the Brazilian states / Import the dataset as an SQL table in the Magist database: 
-- > Imported CSV file with Table data import wizard from CSV from this GITGUB site: https://github.com/datasets-br/state-codescode_states

-- In the following I adapt for the special characters of the imported CSV file: 
SELECT *
FROM country_codes
WHERE state <> CONVERT(state USING ASCII);
 
UPDATE country_codes
SET state = 'Amapá'
WHERE subdivision = "AP";

UPDATE country_codes
SET state = 'Ceará'
WHERE subdivision  = "CE";

UPDATE country_codes
SET state = "Espírito Santo"
WHERE subdivision  = "ES";

UPDATE country_codes
SET state = "Goiás"
WHERE subdivision  = "GO";

UPDATE country_codes
SET state = "Guaporé"
WHERE subdivision  = "GU";

UPDATE country_codes
SET state = "Iguaçu"
WHERE subdivision  = "IG";

UPDATE country_codes
SET state = "Maranhão"
WHERE subdivision  = "Ma";

UPDATE country_codes
SET state = "Pará"
WHERE subdivision  = "PA";

UPDATE country_codes
SET state = "Paraíba"
WHERE subdivision  = "PB";

UPDATE country_codes
SET state = "Piauí"
WHERE subdivision  = "PI";

UPDATE country_codes
SET state = "Ponta Porã"
WHERE subdivision  = "PP";

UPDATE country_codes
SET state = "Paraná"
WHERE subdivision  = "PR";

UPDATE country_codes
SET state = "Rondônia"
WHERE subdivision  = "RO";


UPDATE country_codes
SET state = "São Paulo"
WHERE subdivision  = "SP";

SELECT * FROM country_codes; 


-- Explore tables: 
SELECT * FROM 
country_codes;  

SELECT * FROM geo;


-- 2. Create the appropriate relationships with other tables in the database: 
ALTER TABLE country_codes
RENAME COLUMN name to state;

SELECT * FROM country_codes;

SHOW FULL COLUMNS FROM country_codes; 
SHOW FULL COLUMNS FROM geo; 
SHOW INDEX FROM magist.geo WHERE Key_name = 'PRIMARY';

ALTER TABLE country_codes 
MODIFY subdivision VARCHAR(2);

ALTER TABLE geo
MODIFY state VARCHAR(2);

ALTER TABLE country_codes
DROP PRIMARY KEY;

ALTER TABLE country_codes
ADD PRIMARY KEY (subdivision); 

ALTER TABLE geo
ADD CONSTRAINT constraint_1
FOREIGN KEY (state) 
REFERENCES country_codes(subdivision);


/* 
---------------------------- PART 2: ANALYZE CUSTOMER REVIEWS -----------------------------------------------------
*/ 

-- 3. Find the average review score by state of the customer.

SELECT 
    ROUND(AVG(review_score), 2) AS average_score,
    g.state AS abbreviations,
    cc.state
FROM
    order_reviews ore
        JOIN
    orders o ON ore.order_id = o.order_id
        JOIN
    customers c ON o.customer_id = c.customer_id
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
        JOIN
    country_codes cc ON g.state = cc.subdivision
GROUP BY cc.state; 

-- 4. Do reviews containing positive words have a better score? Some Portuguese positive words are: “bom”, “otimo”, “gostei”, “recomendo” and “excelente”.
--  Answer: Yes, in average they get a score of 4.4 compared to 4.0 (which may also contain positive buzzwords by the way, so the real difference migth be even bigger). 
SELECT 
    ROUND(AVG(review_score), 2) AS average_score,
    COUNT(review_score) AS number_of_reviews,
    CASE
        WHEN
            review_comment_message LIKE ('%bom%')
                OR review_comment_message LIKE ('%otimo%')
                OR review_comment_message LIKE ('%gostei%')
                OR review_comment_message LIKE ('%recomend%')
                OR review_comment_message LIKE ('%excelent%')
                OR review_comment_message LIKE ('%super%')
                OR review_comment_message LIKE ('%satisf%')
        THEN
            'positive'
        ELSE 'not_positive'
    END AS review_status
FROM
    order_reviews
GROUP BY review_status; 

-- 5. Considering only states having at least 30 reviews containing these words, what is the state with the highest score?
-- Answer: The state with the highest average score is "Amapai"

SELECT 
    ROUND(AVG(review_score), 2) AS average_score,
    g.state AS abbreviations,
    cc.state,
    CASE
        WHEN
            review_comment_message LIKE ('%bom%')
                OR review_comment_message LIKE ('%otimo%')
                OR review_comment_message LIKE ('%gostei%')
                OR review_comment_message LIKE ('%recomend%')
                OR review_comment_message LIKE ('%excelent%')
                OR review_comment_message LIKE ('%super%')
                OR review_comment_message LIKE ('%satisf%')
        THEN
            'positive'
        ELSE 'not_positive'
    END AS review_status
FROM
    order_reviews ore
        JOIN
    orders o ON ore.order_id = o.order_id
        JOIN
    customers c ON o.customer_id = c.customer_id
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
        JOIN
    country_codes cc ON g.state = cc.subdivision
GROUP BY cc.state
HAVING COUNT(review_status) >= 30
    AND review_status = 'positive'
ORDER BY average_score DESC
LIMIT 1; 


--  6. What is the state where there is a greater score change between all reviews and reviews containing positive words?
-- Answer - State with biggest score difference btw. all reviews and positive words: Roraima

SELECT average_score, 
	   state,
	   average_score - LAG(average_score) OVER (PARTITION BY abbreviations ORDER BY abbreviations) AS difference
FROM 
	(SELECT ROUND(AVG(review_score), 2) AS average_score, g.state AS abbreviations, cc.state,
	CASE 
		WHEN review_comment_message LIKE ("%bom%") 
								OR review_comment_message LIKE ("%otimo%")
                                OR review_comment_message LIKE ("%gostei%")
                                OR review_comment_message LIKE ("%recomend%")
                                OR review_comment_message LIKE ("%excelent%")
                                OR review_comment_message LIKE ("%super%")
                                OR review_comment_message LIKE ("%satisf%")
                                THEN "positive"
		WHEN review_comment_message LIKE ("%")
								THEN "all_reviews" 
	END AS review_status
	FROM order_reviews ore
	JOIN orders o
	ON ore.order_id = o.order_id
	JOIN customers c
	ON o.customer_id = c.customer_id
	JOIN geo g
	ON c.customer_zip_code_prefix= g.zip_code_prefix 
	JOIN country_codes cc
	ON g.state = cc.subdivision
	GROUP BY cc.state, review_status 
	HAVING review_status is not NULL
	ORDER BY cc.state, review_status) As sub; 


-- Alternative solution: I also get different results. Maybe that's due to missing values? 
DROP TEMPORARY TABLE average_positive_review; 
CREATE TEMPORARY TABLE average_positive_review
SELECT ROUND(AVG(review_score), 2) AS average_score_positive, 
		g.state AS abbreviations, 
        cc.state
FROM order_reviews ore
	JOIN orders o
	ON ore.order_id = o.order_id
	JOIN customers c
	ON o.customer_id = c.customer_id
	JOIN geo g
	ON c.customer_zip_code_prefix= g.zip_code_prefix 
	JOIN country_codes cc
	ON g.state = cc.subdivision
    WHERE review_comment_message LIKE ("%bom%") 
		  OR review_comment_message LIKE ("%otimo%")
		  OR review_comment_message LIKE ("%gostei%")
		  OR review_comment_message LIKE ("%recomend%")
		  OR review_comment_message LIKE ("%excelent%")
		  OR review_comment_message LIKE ("%super%")
	      OR review_comment_message LIKE ("%satisf%")
	GROUP BY cc.state; 
 
 
CREATE TEMPORARY TABLE average_all_reviews
SELECT ROUND(AVG(review_score), 2) AS average_score_all, 
		g.state AS abbreviations, 
        cc.state
FROM order_reviews ore
	JOIN orders o
	ON ore.order_id = o.order_id
	JOIN customers c
	ON o.customer_id = c.customer_id
	JOIN geo g
	ON c.customer_zip_code_prefix= g.zip_code_prefix 
	JOIN country_codes cc
	ON g.state = cc.subdivision
    GROUP BY cc.state; 

SELECT 
    aar.average_score_all,
    apr.average_score_positive,
    aar.abbreviations,
    aar.state,
    apr.average_score_positive - aar.average_score_all AS difference
FROM
    average_all_reviews AS aar
        JOIN
    average_positive_review apr ON aar.abbreviations = apr.abbreviations
ORDER BY difference DESC; 



/* 
--------------------- PART 3: AUTOMATIZE A KPI ---------------------------------------
*/ 

/* 
7.  Create a stored procedure that gets as input:
    - The name of a state (the full name from the table you imported).
    - The name of a product category (in English).
	- A year
    
    --> And outputs the average score for reviews left by customers from the given state for orders with the status “delivered, 
    containing at least a product in the given category, and placed on the given year.
*/ 

DELIMITER $$
CREATE PROCEDURE average_score (
								IN state VARCHAR (255), 
								IN category VARCHAR(255), 
                                IN put_year YEAR)
BEGIN

SELECT ROUND(AVG(review_score), 2) AS average_score,
COUNT(review_score) AS num_of_reviews,
g.state AS abbreviations,
cc.state
FROM order_reviews ore
JOIN orders o
ON ore.order_id = o.order_id
JOIN customers c
ON o.customer_id = c.customer_id
JOIN geo g
ON c.customer_zip_code_prefix= g.zip_code_prefix 
JOIN country_codes cc
ON g.state = cc.subdivision
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
JOIN product_category_name_translation pcnt
ON p.product_category_name = pcnt.product_category_name
WHERE order_status = "delivered" 
    AND EXTRACT(YEAR FROM o.order_purchase_timestamp) = put_year
    AND pcnt.product_category_name_english LIKE category
    AND cc.state = state
HAVING COUNT(pcnt.product_category_name_english) >=1;

END$$ 
DELIMITER ;

	
CALL average_score("Rondônia", "telephony", 2017); 
