-- Step 1: Create the Database (Run this separately in PostgreSQL)
CREATE DATABASE walmart;

-- Step 2: Switch to the Walmart Database
\c walmart;

-- Step 3: Create the Table
CREATE TABLE sales (
    invoice_id VARCHAR(30) PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    vat FLOAT NOT NULL,
    total DECIMAL(12,4) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT,
    gross_income DECIMAL(12,4),
    rating FLOAT
);

-- Step 4: Load Data from Local CSV File
-- Ensure the CSV file path is correct!
\copy sales FROM 'D:/Walmart_Project/Walmart_Sales_Data.csv' DELIMITER ',' CSV HEADER;

-- Step 5: Verify Data is Loaded
SELECT * FROM sales LIMIT 5;

------------------- Feature Engineering -----------------------------

-- 1. Time_of_day Column
ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

UPDATE sales
SET time_of_day = (
    CASE 
        WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening' 
    END
);

-- 2. Day_name Column
ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = TO_CHAR(date, 'Day');

-- 3. Month_name Column
ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales
SET month_name = TO_CHAR(date, 'Month');

---------------- Exploratory Data Analysis (EDA) ----------------------

-- 1. Number of distinct cities
SELECT COUNT(DISTINCT city) FROM sales;

-- 2. City and branch mapping
SELECT DISTINCT branch, city FROM sales;

-- Product Analysis --

-- 1. Distinct product lines
SELECT COUNT(DISTINCT product_line) FROM sales;

-- 2. Most common payment method
SELECT payment, COUNT(payment) AS common_payment_method
FROM sales GROUP BY payment ORDER BY common_payment_method DESC LIMIT 1;

-- 3. Most selling product line
SELECT product_line, COUNT(product_line) AS most_selling_product
FROM sales GROUP BY product_line ORDER BY most_selling_product DESC LIMIT 1;

-- 4. Total revenue by month
SELECT month_name, SUM(total) AS total_revenue
FROM sales GROUP BY month_name ORDER BY total_revenue DESC;

-- 5. Month with highest Cost of Goods Sold (COGS)
SELECT month_name, SUM(cogs) AS total_cogs
FROM sales GROUP BY month_name ORDER BY total_cogs DESC;

-- 6. Product line with highest revenue
SELECT product_line, SUM(total) AS total_revenue
FROM sales GROUP BY product_line ORDER BY total_revenue DESC LIMIT 1;

-- 7. City with highest revenue
SELECT city, SUM(total) AS total_revenue
FROM sales GROUP BY city ORDER BY total_revenue DESC LIMIT 1;

-- 8. Product line with highest VAT
SELECT product_line, SUM(vat) AS VAT 
FROM sales GROUP BY product_line ORDER BY VAT DESC LIMIT 1;

-- 9. Add a product_category column and classify as "Good" or "Bad"
ALTER TABLE sales ADD COLUMN product_category VARCHAR(20);

UPDATE sales 
SET product_category = 
    CASE 
        WHEN total >= (SELECT AVG(total) FROM sales) THEN 'Good'
        ELSE 'Bad'
    END;

-- 10. Branches selling above the average number of products
SELECT branch, SUM(quantity) AS quantity
FROM sales 
GROUP BY branch 
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales) 
ORDER BY quantity DESC LIMIT 1;

-- 11. Most common product line by gender
SELECT gender, product_line, COUNT(gender) AS total_count
FROM sales GROUP BY gender, product_line ORDER BY total_count DESC;

-- 12. Average rating per product line (Fixed ROUND issue)
SELECT product_line, ROUND(AVG(rating)::numeric, 2) AS average_rating
FROM sales GROUP BY product_line ORDER BY average_rating DESC;

-- Sales Analysis --

-- 1. Sales per weekday and time of day (excluding weekends)
SELECT day_name, time_of_day, COUNT(invoice_id) AS total_sales
FROM sales WHERE day_name NOT IN ('Saturday', 'Sunday') 
GROUP BY day_name, time_of_day;

-- 2. Customer type with highest revenue
SELECT customer_type, SUM(total) AS total_sales
FROM sales GROUP BY customer_type ORDER BY total_sales DESC LIMIT 1;

-- 3. City with highest VAT percentage
SELECT city, SUM(vat) AS total_vat
FROM sales GROUP BY city ORDER BY total_vat DESC LIMIT 1;

-- 4. Customer type that pays the most in VAT
SELECT customer_type, SUM(vat) AS total_vat
FROM sales GROUP BY customer_type ORDER BY total_vat DESC LIMIT 1;

-- Customer Analysis --

-- 1. Unique customer types
SELECT COUNT(DISTINCT customer_type) FROM sales;

-- 2. Unique payment methods
SELECT COUNT(DISTINCT payment) FROM sales;

-- 3. Most common customer type
SELECT customer_type, COUNT(customer_type) AS common_customer
FROM sales GROUP BY customer_type ORDER BY common_customer DESC LIMIT 1;

-- 4. Customer type that buys the most
SELECT customer_type, COUNT(*) AS most_buyer
FROM sales GROUP BY customer_type ORDER BY most_buyer DESC LIMIT 1;

-- 5. Gender distribution of customers
SELECT gender, COUNT(*) AS total_count 
FROM sales GROUP BY gender ORDER BY total_count DESC;

-- 6. Gender distribution per branch
SELECT branch, gender, COUNT(gender) AS gender_distribution
FROM sales GROUP BY branch, gender ORDER BY branch;

-- 7. Time of day with highest average ratings
SELECT time_of_day, ROUND(AVG(rating)::numeric, 2) AS average_rating
FROM sales GROUP BY time_of_day ORDER BY average_rating DESC LIMIT 1;

-- 8. Time of day with highest average ratings per branch
SELECT branch, time_of_day, ROUND(AVG(rating)::numeric, 2) AS average_rating
FROM sales GROUP BY branch, time_of_day ORDER BY average_rating DESC;

-- 9. Day of the week with best average ratings
SELECT day_name, ROUND(AVG(rating)::numeric, 2) AS average_rating
FROM sales GROUP BY day_name ORDER BY average_rating DESC LIMIT 1;

-- 10. Best average ratings per branch
SELECT branch, day_name, ROUND(AVG(rating)::numeric, 2) AS average_rating
FROM sales GROUP BY branch, day_name ORDER BY average_rating DESC;
