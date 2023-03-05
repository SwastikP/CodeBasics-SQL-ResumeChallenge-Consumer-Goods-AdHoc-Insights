/*
1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.
*/

SELECT DISTINCT MARKET FROM gdb023.dim_customer WHERE REGION='APAC' AND CUSTOMER="Atliq Exclusive"

/*
2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg
*/

WITH CTE_UNIQUE_PRODUCT_2020 AS (
SELECT COUNT(DISTINCT PRODUCT_CODE) AS UNIQUE_PRODUCTS_2020 FROM gdb023.fact_sales_monthly
WHERE fiscal_year=2020),
CTE_UNIQUE_PRODUCT_2021 AS (
SELECT COUNT(DISTINCT PRODUCT_CODE) AS UNIQUE_PRODUCTS_2021 FROM gdb023.fact_sales_monthly
WHERE fiscal_year=2021)
SELECT UNIQUE_PRODUCTS_2020,UNIQUE_PRODUCTS_2021,
ROUND((UNIQUE_PRODUCTS_2021-UNIQUE_PRODUCTS_2020)*100.0/UNIQUE_PRODUCTS_2020,2) AS PERCENTAGE_CHG
FROM CTE_UNIQUE_PRODUCT_2020 CROSS JOIN CTE_UNIQUE_PRODUCT_2021

/*
3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count
*/
SELECT segment,COUNT(DISTINCT product_code) as 'product_count' FROM gdb023.dim_product
GROUP BY segment
ORDER BY 2 DESC;

/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/

with cte_2020 as(
SELECT prod.segment,COUNT(DISTINCT prod.product_code) as 'product_count_2020'
 FROM gdb023.dim_product prod join gdb023.fact_sales_monthly sales 
on prod.product_code=sales.product_code where sales.fiscal_year=2020
group by prod.segment),
cte_2021 as(
SELECT prod.segment,COUNT(DISTINCT prod.product_code) as 'product_count_2021'
 FROM gdb023.dim_product prod join gdb023.fact_sales_monthly sales 
on prod.product_code=sales.product_code where sales.fiscal_year=2021
group by prod.segment)
select c1.segment,c1.product_count_2020,c2.product_count_2021,c2.product_count_2021-c1.product_count_2020 as difference 
from cte_2020 c1 inner join cte_2021 c2
on c1.segment=c2.segment order by difference asc;

/*
5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost
*/
SELECT prod.product_code,prod.product,man.manufacturing_cost FROM gdb023.fact_manufacturing_cost man INNER JOIN gdb023.dim_product prod 
ON man.product_code=prod.product_code WHERE man.manufacturing_cost=(SELECT max(manufacturing_cost) from gdb023.fact_manufacturing_cost)
OR man.manufacturing_cost=(SELECT min(manufacturing_cost) from gdb023.fact_manufacturing_cost)

/*
6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/

SELECT dis.customer_code,cus.customer,ROUND(100.0*avg(dis.pre_invoice_discount_pct),2) as 'average_discount_percentage'
FROM gdb023.fact_pre_invoice_deductions dis INNER JOIN gdb023.dim_customer cus
ON dis.customer_code=cus.customer_code WHERE dis.fiscal_year=2021 and cus.market='India' 
GROUP BY dis.customer_code,cus.customer
ORDER BY 3 DESC LIMIT 5

/*
7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/
SELECT monthname(date) as `month`,year(date) as `Year`,ROUND(sum(sales.sold_quantity*gross.gross_price),2) as 'Gross sales Amount'
FROM gdb023.fact_sales_monthly sales INNER JOIN gdb023.fact_gross_price gross ON sales.product_code=gross.product_code 
INNER JOIN gdb023.dim_customer cus ON sales.customer_code=cus.customer_code
WHERE cus.customer="Atliq Exclusive" GROUP BY 1,2 ORDER BY 2
/*
8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
*/

SELECT
CASE
	WHEN monthname(date) in ('September','October','November') THEN "Q1 of 2020"
	WHEN monthname(date) in ('December','January','February') THEN "Q2 of 2020"
	WHEN monthname(date) in ('March','April','May') THEN "Q3 of 2020"
	WHEN monthname(date) in ('June','July','August') THEN "Q4 of 2020"
END as Quarter,
sum(sold_quantity) as total_sales FROM fact_sales_monthly WHERE fiscal_year="2020"
GROUP BY Quarter ORDER BY total_sales DESC;

/*
9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
*/
with total_sales_f2021 as(
SELECT cus.channel,ROUND(sum(sales.sold_quantity*gross.gross_price)/1000000,2) as 'gross_sales_mln'
FROM gdb023.fact_sales_monthly sales INNER JOIN gdb023.fact_gross_price gross 
ON sales.product_code=gross.product_code 
INNER JOIN gdb023.dim_customer cus
ON sales.customer_code=cus.customer_code
WHERE sales.fiscal_year=2021 and gross.fiscal_year=2021
GROUP BY 1
ORDER BY 2 DESC)
select total_sales_f2021.channel,total_sales_f2021.gross_sales_mln,
ROUND(100.0*total_sales_f2021.gross_sales_mln/sum(total_sales_f2021.gross_sales_mln) over(),2) as percentage 
from total_sales_f2021
/*
10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
codebasics.io
product
total_sold_quantity
rank_order
*/


with cte_total_sales as(
SELECT prod.division,prod.product_code,prod.product,sum(sales.sold_quantity) as total_sold_quantity
FROM gdb023.dim_product prod INNER JOIN gdb023.fact_sales_monthly sales
ON prod.product_code=sales.product_code
WHERE sales.fiscal_year=2021
GROUP BY 1,2,3),
cte_top3 as (
select cte_total_sales.division,cte_total_sales.product_code,cte_total_sales.product,cte_total_sales.total_sold_quantity,
rank() over(partition by cte_total_sales.division order by cte_total_sales.total_sold_quantity desc) as rank_order 
from cte_total_sales) 
select * from cte_top3 where rank_order<=3

