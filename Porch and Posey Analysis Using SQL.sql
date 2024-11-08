/*
THIS PROJECT IS AN IN DEPTH ANALYSIS OF THE DATABASE OF A FICTICIOUS COMPANY CALLED PORCH AND POSEY.
A GLANCE INTO THE ERD OF THE DATABASE CAN BE FOUND IN THE README FILE
THE QUERIES BELOW ANSWERS OVER 30 BUSINESS QUESTIONS FOR DRIVING DECISION MAKING IN PORCH AND POSEY
*/


/*1. Find the total amount spent on standard_amt_usd and gloss_amt_usd paper for each order in the orders table. 
This should give a dollar amount for each order in the table.*/
SELECT standard_amt_usd+gloss_amt_usd as total_standard_gloss
FROM orders;


--2. Which day was the earliest order ever placed and the most recent (latest) web_event occur?
SELECT DATE_TRUNC('day',MIN(o.occurred_at)) as earliest_order_date, 
       DATE_TRUNC('day',MAX(w.occurred_at)) as latest_event
FROM orders as O
JOIN web_events as w
ON o.account_id = w.account_id


/*3. Find the mean (AVERAGE) amount spent per order on each paper type, as well as the mean amount of each paper 
type purchased per order. Your final answer should have 6 values - one for each paper type for the average number of sales, 
as well as the average amount.*/
SELECT AVG(standard_qty) as avg_standard_qty,
       AVG(gloss_qty) as avg_gloss_qty,
       AVG(poster_qty) as avg_poster_qty,
       AVG(standard_amt_usd) as avg_standard_amt,
       AVG(gloss_amt_usd) as avg_gloss_amt,
       AVG(poster_amt_usd) as avg_poster_amt
FROM orders


/*4. What is the MEDIAN total_usd spent on all orders?*/
SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY total_amt_usd) as median_total_amt_usd
FROM orders


/*5. For each account, determine the average amount spent per order on each paper type. Your result should have four columns - one 
for the account name and one for the average amount spent on each paper type.*/
SELECT a.name,
       AVG(standard_amt_usd) as avg_standard_amt,
       AVG(gloss_amt_usd) as avg_gloss_amt,
       AVG(poster_amt_usd) as avg_poster_amt
FROM orders as o
JOIN accounts as a
ON a.id = o.account_id
GROUP BY a.name


/*6. Determine the number of times a particular channel was used in the web_events table for each sales rep. Your final table should 
have three columns - the name of the sales rep, the channel, and the number of occurrences. Order your table with the highest number 
of occurrences first.*/
SELECT s.name,
       w.channel,
       COUNT(*) as no_of_occurrences
FROM sales_reps as s
JOIN accounts as a
ON a.sales_rep_id = s.id
JOIN web_events as w
ON w.account_id = a.id
GROUP BY s.name,w.channel
ORDER BY no_of_occurrences DESC


/*7. Determine the number of times a particular channel was used in the web_events table for each region. Your final table should have 
three columns - the region name, the channel, and the number of occurrences. Order your table with the highest number of occurrences 
first.*/
SELECT r.name,
       w.channel,
       COUNT(*) as no_of_occurrences
FROM region as r
JOIN sales_reps as s
ON r.id = s.region_id
JOIN accounts as a
ON a.sales_rep_id = s.id
JOIN web_events as w
ON w.account_id = a.id
GROUP BY r.name,w.channel
ORDER BY no_of_occurrences DESC


/*8. We would like to understand 3 different levels of customers based on the amount associated with their purchases.
The top level includes anyone with a Lifetime Value (total sales of all orders) greater than 200,000 usd. The second level is 
between 200,000 and 100,000 usd. The lowest level is anyone under 100,000 usd. Provide a table that includes the level associated with 
each account. You should provide the account name, the total sales of all orders for the customer, and the level. Order with the top 
spending customers listed first.*/

--8 a
SELECT a.name,
       SUM(total_amt_usd) as total_sales,
       CASE WHEN SUM(total_amt_usd) > 200000 THEN 'Top Level'
            WHEN SUM(total_amt_usd) BETwEEN 100000 AND 200000 THEN 'Mid Level'
            ELSE 'Low Level' END AS level
FROM orders as o
JOIN accounts as a
ON a.id = o.account_id
GROUP BY a.name
ORDER BY total_sales DESC

--8 b  Filter for only 2016 and 2017. 
SELECT a.name,
       SUM(total_amt_usd) as total_sales,
       CASE WHEN SUM(total_amt_usd) > 200000 THEN 'Top Level'
            WHEN SUM(total_amt_usd) BETwEEN 100000 AND 200000 THEN 'Mid Level'
            ELSE 'Low Level' END AS level
FROM orders as o
JOIN accounts as a
ON a.id = o.account_id
WHERE occurred_at BETwEEN '2016-01-01' AND '2017-12-31'
GROUP BY a.name
ORDER BY total_sales DESC


/*9. We would like to identify top performing sales reps, which are sales reps associated with more than 200 orders or more than 750000 
in total sales. The middle group has any rep with more than 150 orders or 500000 in sales. Create a table with the sales rep name, 
the total number of orders, total sales across all orders, and a column with top, middle, or low depending on this criteria. 
Place the top sales people based on dollar amount of sales first in your final table. You might see a few upset sales people by 
this criteria!*/
SELECT s.name,
       COUNT(total) as total_orders,
       SUM(total_amt_usd) as total_amt_usd,
       CASE WHEN COUNT(total) > 200 OR SUM(total_amt_usd) > 750000 THEN 'Top performer'
            WHEN COUNT(total) BETwEEN 100 AND 200 OR SUM(total_amt_usd) BETwEEN 500000 AND 750000 THEN 'Mid performer'
            ELSE 'Low performer' END AS performance_level
FROM sales_reps as s
JOIN accounts as a
ON a.sales_rep_id = s.id
JOIN orders as o
ON o.account_id = a.id
GROUP BY s.name
ORDER BY total_amt_usd DESC


--10. Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.
WITH regional_sales_total AS 
       (SELECT r.name as region, 
               s.name as sales_rep, 
               SUM(o.total_amt_usd) as total_sales
       FROM orders o
       JOIN accounts a
       ON a.id = o.account_id
       JOIN sales_reps s
       ON s.id = a.sales_rep_id
       JOIN region r
       ON r.id = s.region_id
       GROUP BY r.name, s.name
       ORDER BY total_sales DESC),

       regional_sales_max AS 
       (SELECT region, 
               MAX(total_sales) as max_sales
       FROM regional_sales_total
       GROUP BY region)
  
 SELECT tot_sal.region, tot_sal.sales_rep, max_sal.max_sales
 FROM regional_sales_total tot_sal
 JOIN regional_sales_max max_sal
 ON tot_sal.region = max_sal.region AND tot_sal.total_sales = max_sal.max_sales;
 

--11. For the region with the largest sales total_amt_usd, how many total orders were placed?
WITH sales_table AS 
       (SELECT o.id, o.total_amt_usd, r.name as region
       FROM orders o
       JOIN accounts a
       ON a.id = o.account_id
       JOIN sales_reps s
       ON s.id = a.sales_rep_id
       JOIN region r
       ON r.id = s.region_id
       ),
  
       max_sales AS 
       (SELECT region, 
              SUM(total_amt_usd) as total_sales
       FROM sales_table
       GROUP BY region
       ORDER BY total_sales DESC
       LIMIT 1
       )

SELECT s.region,
       COUNT(*) as total_order_count
FROM sales_table s
JOIN max_sales m
ON s.region = m.region
GROUP BY s.region;


/*12. How many accounts had more total purchases than the account name which has bought the most standard_qty paper throughout their 
lifetime as a customer?*/
WITH top_acc_stand AS 
       (SELECT a.name, 
               SUM(standard_qty) as total_stand_qty,
               SUM(total) as total_qty
       FROM accounts a
       JOIN orders o
       ON o.account_id = a.id
       GROUP BY a.name
       ORDER BY total_stand_qty DESC
       LIMIT 1                 
       ),

       acc_total_qty_per_order AS 
       (SELECT a.name, 
               SUM(o.total) as total_qty
       FROM accounts a
       JOIN orders o
       ON o.account_id = a.id
       GROUP BY a.name                            
       ),

       acc_of_interest AS 
       (SELECT acc.name,
               SUM(total_qty)
       FROM acc_total_qty_per_order as acc
       GROUP BY acc.name
       HAVING SUM(total_qty) > (SELECT SUM(total_qty) FROM top_acc_stand)
       )                    

SELECT COUNT(*) as no_of_acc_with_more_total_purchases_than_the_top_stand_qty_acc
FROM acc_of_interest;


/* 13. For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, how many web_events did they 
have for each channel?*/
WITH top_customer AS 
       (SELECT o.account_id,
               a.name as name,
               SUM(o.total_amt_usd) as total_sales
       FROM orders o
       JOIN accounts a
       ON a.id = o.account_id
       GROUP BY o.account_id,a.name
       ORDER BY total_sales DESC
       LIMIT 1)

SELECT a.name,
       w.channel,
       COUNT(*) as event_count
FROM web_events as w
JOIN accounts as a
ON a.id = w.account_id
WHERE a.name = (SELECT name FROM top_customer)
GROUP BY a.name,w.channel
ORDER BY event_count DESC;


--14. What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?
WITH top_10_acc AS 
       (SELECT a.name,
               SUM(total_amt_usd) as total_sales
       FROM accounts as a
       JOIN orders as o
       ON o.account_id = a.id
       GROUP BY a.name
       ORDER BY total_sales DESC
       LIMIT 10)

SELECT ROUND(AVG(total_sales),2)
FROM top_10_acc;


/*15. What is the lifetime average amount spent in terms of total_amt_usd, including only the companies that spent more per order, 
on average, than the average of all orders.*/
WITH avg_per_order AS 
       (SELECT AVG(total_amt_usd) as avg_per_order
       FROM accounts as a
       JOIN orders as o
       ON o.account_id = a.id),

       acc_avg_amt AS 
       (SELECT a.name,
              AVG(total_amt_usd) as avg_amt_spent
       FROM accounts as a
       JOIN orders as o
       ON o.account_id = a.id
       GROUP BY a.name
)

SELECT ROUND(AVG(avg_amt_spent),2) as avg_amt_spent
FROM acc_avg_amt
WHERE avg_amt_spent > (SELECT avg_per_order FROM avg_per_order);


/*16. In the accounts table, there is a column holding the website for each company. The last three digits specify what type of 
web address they are using. Pull these extensions and provide how many of each website type exist in the accounts table.*/
SELECT RIGHT(website,3) as domain,
       COUNT(*) as no_of_domains
FROM accounts
GROUP BY 1
ORDER BY 2 DESC;


/*17. There is much debate about how much the name (or even the first letter of a company name)(opens in a new tab) matters. 
Use the accounts table to pull the first letter of each company name to see the distribution of company names that begin 
with each letter (or number).*/
SELECT LEFT(name,1) as first_letter,
       COUNT(*) as letter_count
FROM accounts
GROUP BY 1
ORDER BY 2 DESC;


/*18. Use the accounts table and a CASE statement to create two groups: one group of company names that start with a number and a 
second group of those company names that start with a letter. What proportion of company names start with a letter?*/
SELECT CASE WHEN (LEFT(name,1)) ~ '^[0-9]+$' THEN 'Names starting with numbers'
       ELSE 'Names starting with letters' END AS companies_first_character,
       COUNT(*)
FROM accounts
GROUP BY 1
ORDER BY 2 DESC;


--19. Consider vowels as a, e, i, o, and u. What proportion of company names start with a vowel, and what percent start with anything else?
WITH letters AS 
       (SELECT name, 
               CASE WHEN LEFT(UPPER(name), 1) IN ('A','E','I','O','U') 
                                   THEN 1 ELSE 0 END AS vowels, 
               CASE WHEN LEFT(UPPER(name), 1) IN ('A','E','I','O','U') 
                                   THEN 0 ELSE 1 END AS other
       FROM accounts)              

SELECT SUM(vowels) as vowels, 
       SUM(other) as other
FROM letters;


/*20. Use the accounts table to create first and last name columns that hold the first and last names for the primary_poc and for 
every rep name in the sales_reps table*/
--20 a
SELECT a.primary_poc,
       LEFT(primary_poc,STRPOS(primary_poc, ' ')-1) AS first_name,
       RIGHT(primary_poc,LENGTH(primary_poc)-STRPOS(primary_poc, ' ')) AS last_name
FROM accounts as a;

--20 b
SELECT name,
       LEFT(name,STRPOS(name, ' ')-1) AS first_name,
       RIGHT(name,LENGTH(name)-STRPOS(name, ' ')) AS last_name
FROM sales_reps s;


/*21. Each company in the accounts table wants to create an email address for each primary_poc. The email address should be the first 
name of the primary_poc . last name primary_poc @ company name .domain name (in the website).
Some of the company names include spaces, which will certainly not work in an email address. Ensure you take care of that too.*/
WITH names AS 
       (SELECT primary_poc, name, website,
               LEFT(LOWER(primary_poc),STRPOS(primary_poc,' ')-1) as first_name,
               RIGHT(LOWER(primary_poc),LENGTH(primary_poc)-STRPOS(primary_poc,' ')) as last_name   
       FROM accounts)

SELECT primary_poc,
       name,
       CONCAT(first_name,'.',last_name,'@',LOWER(REPLACE(name,' ','')),RIGHT(LOWER(website),4)) as email_address  
FROM names;


/*22. We would also like to create an initial password, which they will change after their first log in. 
The first password will be the first letter of the primary_poc's first name (lowercase), then the last letter of their 
first name (lowercase), the first letter of their last name (lowercase), the last letter of their last name (lowercase), 
the number of letters in their first name, the number of letters in their last name, and then the name of the company 
they are working with, all capitalized with no spaces.*/
WITH names AS 
       (SELECT primary_poc, name,
               LEFT(LOWER(primary_poc),STRPOS(primary_poc,' ')-1) as first_name,
               RIGHT(LOWER(primary_poc),LENGTH(primary_poc)-STRPOS(primary_poc,' ')) as last_name   
       FROM accounts)                                                              

SELECT primary_poc,
       name,
       CONCAT(LEFT(LOWER(first_name),1),
              RIGHT(first_name,1),
              LEFT(last_name,1),
              RIGHT(last_name,1),
              LENGTH(first_name),
              LENGTH(last_name),
              UPPER(REPLACE(name,' ',''))
             ) AS password                            
FROM names     


/* 23 Create a running total of standard_amt_usd (in the orders table) over order time with no date truncation. 
Your final table should have two columns: one with the amount being added for each new row, and a second with the running total.*/
SELECT standard_amt_usd,
       SUM(standard_amt_usd) OVER(ORDER BY occurred_at) AS running_total
FROM orders


/* 24 Create a running total & moving average of standard_amt_usd (in the orders table) over order time, but this time, date truncate 
occurred_at by year and partition by that same year-truncated occurred_at variable. Your final table should have four columns: 
One with the amount being added for each row, one for the truncated date, and one each for the running total and moving average 
within each year.*/
SELECT standard_amt_usd,
       DATE_TRUNC('year',occurred_at) as year,
       AVG(standard_amt_usd) OVER(PARTITION BY DATE_TRUNC('year',occurred_at) ORDER BY occurred_at) as moving_average,
       SUM(standard_amt_usd) OVER(PARTITION BY DATE_TRUNC('year',occurred_at) ORDER BY occurred_at) as running_total
FROM orders       


/* 25 Select the id, account_id, and total variable from the orders table, then create a column called total_rank that ranks 
this total amount of paper ordered (from highest to lowest) for each account using a partition. Your final table should 
have these four columns.*/
SELECT id, 
       account_id, 
       total,
       RANK() OVER(PARTITION BY account_id ORDER BY total DESC) as total_rank
FROM orders 


/* 26 Select the id, account_id, standard_qty, a partitioned date by month, and the ranked sum, average, count, minimum, 
and maximum standard_qty. Ensure the rank does not skip numbers*/
SELECT id,
       account_id,
       standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       DENSE_RANK() OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS dense_rank,
       SUM(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS sum_std_qty,
       COUNT(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS count_std_qty,
       AVG(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS avg_std_qty,
       MIN(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS min_std_qty,
       MAX(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS max_std_qty
FROM orders


/* 27 Working with window function aliases. Alias the code in 26 above with a window clause*/
SELECT id,
       account_id,
       standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       DENSE_RANK() OVER rank_window AS dense_rank,
       SUM(standard_qty) OVER rank_window AS sum_std_qty,
       COUNT(standard_qty) OVER rank_window AS count_std_qty,
       AVG(standard_qty) OVER rank_window AS avg_std_qty,
       MIN(standard_qty) OVER rank_window AS min_std_qty,
       MAX(standard_qty) OVER rank_window AS max_std_qty
FROM orders
WINDOW rank_window AS (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at))


/* 28 Imagine you're an analyst at Parch & Posey and you want to determine how the current order's total revenue, 
("total" meaning from sales of all types of paper) compares to the next order's total revenue. */
SELECT account_id,
       total_amt_usd,
       LEAD(total_amt_usd) OVER (ORDER BY occurred_at) AS lead,
       LEAD(total_amt_usd) OVER (ORDER BY occurred_at) - total_amt_usd AS lead_difference
FROM orders


/* 29 Determine how the current month order's total revenue, compares to the next month order's total revenue.*/
WITH monthly_revenue AS 
       (SELECT DATE_TRUNC('month', occurred_at) as month,
               SUM(total_amt_usd) as total_amt_usd
       FROM orders
       GROUP BY 1)

SELECT month,
       total_amt_usd,
       LEAD(total_amt_usd) OVER (ORDER BY month) AS next_month_revenue,
       LEAD(total_amt_usd) OVER (ORDER BY month) - total_amt_usd AS revenue_difference
FROM monthly_revenue


/* 30 Use the NTILE functionality to divide the accounts into 4 levels in terms of the amount of standard_qty for their orders. 
Your resulting table should have the account_id, the occurred_at time for each order, the total amount of standard_qty paper 
purchased, and one of four levels in a standard_quartile column.*/
SELECT account_id,
       occurred_at,
       standard_qty,
       NTILE(4) OVER(PARTITION BY account_id ORDER BY standard_qty) as standard_quartile
FROM orders
ORDER BY account_id

/* 31 Use the NTILE functionality to divide the orders for each account into 100 levels in terms of the amount of total_amt_usd 
for their orders. Your resulting table should have the account_id, the occurred_at time for each order, the total amount of 
total_amt_usd paper purchased, and one of 100 levels in a total_percentile column.*/
SELECT account_id,
       occurred_at,
       total_amt_usd,
       NTILE(100) OVER(PARTITION BY account_id ORDER BY total_amt_usd) as total_percentile
FROM orders
ORDER BY account_id


