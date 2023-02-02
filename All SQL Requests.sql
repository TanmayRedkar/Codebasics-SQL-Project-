Request 1: Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
 business in the  APAC  region
SELECT 
    *
FROM
    gdb023.dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC'
------------------------------------------------------------------------------------------------------------------
Request 2 :  What is the percentage of unique product increase in 2021 vs. 2020? The 
 final output contains these fields, 
 unique_products_2020 
 unique_products_2021 
 percentage_chg 

with cte as (SELECT count(distinct case when fiscal_year = 2020 then product_code else null end) AS Unique_Product_2020,
count(distinct case when fiscal_year = 2021 then product_code else null end) AS Unique_Product_2021
FROM gdb023.fact_sales_monthly)
select *, concat(round(100*(1- Unique_Product_2020/Unique_Product_2021),2), "%") as Percentage_Change 
FROM cte
--------------------------------------------------------------------------------------------------------------------
Request 3 :  Provide a report with all the unique product counts for each  segment  and 
 sort them in descending order of product counts. The final output contains 
 2 fields, 
 segment 
 product_count 
 SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC;
--------------------------------------------------------------------------------------------------------------------
Request 4 :   Follow-up: Which segment had the most increase in unique products in 
 2021 vs 2020? The final output contains these fields, 
 segment 
 product_count_2020 
 product_count_2021 
 difference 
 
with cte as (
SELECT products_table.segment,
 count(distinct products_table.product_code) as product_count_2020
FROM gdb023.dim_product as products_table inner join fact_sales_monthly as monthly_sales
on products_table.product_code = monthly_sales.product_code
where fiscal_year = 2020
group by products_table.segment
order by product_count_2020 desc
)
,cte1 as (
SELECT products_table.segment,
 count(distinct products_table.product_code) as product_count_2021
FROM gdb023.dim_product as products_table inner join fact_sales_monthly as monthly_sales
on products_table.product_code = monthly_sales.product_code
where fiscal_year = 2021
group by products_table.segment
order by product_count_2021 desc
)
SELECT cte.segment, product_count_2020, product_count_2021, 
(product_count_2021-product_count_2020) as Difference
from cte inner join cte1 
on cte.segment = cte1.segment
order by Difference desc
--------------------------------------------------------------------------------------------------------------------------------
Request 5 :Get the products that have the highest and lowest manufacturing costs. 
 The final output should contain these fields, 
 product_code 
 product 
 manufacturing_cost 
 SELECT DISTINCT
    product_table.product_code,
    product_table.product,
    manufacturing_cost.manufacturing_cost
FROM
    gdb023.dim_product AS product_table
        INNER JOIN
    gdb023.fact_manufacturing_cost AS manufacturing_cost ON product_table.product_code = manufacturing_cost.product_code
WHERE
    manufacturing_cost.manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            gdb023.fact_manufacturing_cost)
        OR manufacturing_cost.manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            gdb023.fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC
-------------------------------------------------------------------------------------------------------------------------------------
Request 6 :  Generate a report which contains the top 5 customers who received an 
 average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
 Indian  market. The final output contains these fields, 
 customer_code 
 customer 
 average_discount_percentage 
 SELECT 
    customer_table.customer_code,
    customer_table.customer,
    ROUND((AVG(invoice_table.pre_invoice_discount_pct)) * 100,
            2) AS average_discount_percentage
FROM
    gdb023.dim_customer AS customer_table
        INNER JOIN
    gdb023.fact_pre_invoice_deductions AS invoice_table ON customer_table.customer_code = invoice_table.customer_code
WHERE
    invoice_table.fiscal_year = 2021
        AND customer_table.market = 'India'
GROUP BY customer_table.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;
-----------------------------------------------------------------------------------------------------------------------------------------
Request 7 : Get the complete report of the Gross sales amount for the customer  “Atliq 
 Exclusive”  for each month 
 .  This analysis helps to  get an idea of low and 
 high-performing months and take strategic decisions. 
 The final report contains these columns: 
 Month 
 Year 
 Gross sales Amount 
 SELECT monthname(monthly_sales.date) AS Month, monthly_sales.fiscal_year AS Year,
    SUM(ROUND((gross_table.gross_price * monthly_sales.sold_quantity),2)) / 1000000 AS gross_sales_amount
FROM gdb023.dim_customer AS customer_table JOIN
    gdb023.fact_sales_monthly AS monthly_sales ON
    customer_table.customer_code = monthly_sales.customer_code JOIN
    fact_gross_price as gross_table on 
    gross_table.fiscal_year = monthly_sales.fiscal_year and 
    gross_table.product_code = monthly_sales.product_code
    WHERE customer_table.customer = 'Atliq Exclusive' 
    GROUP BY Month , Year
------------------------------------------------------------------------------------------------------------------------------------
Request 8 : In which quarter of 2020, got the maximum total_sold_quantity? The final 
 output contains these fields sorted by the total_sold_quantity, 
 Quarter 
 total_sold_quantity 
 SELECT CASE 
          WHEN MONTH(date)  IN  (9,10,11) THEN 'Q1'
          WHEN MONTH(date) IN  (12,1,2) THEN 'Q2'
          WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
          WHEN MONTH(date) IN (6,7,8) THEN 'Q4'
      END AS Quarter,
round(sum(sold_quantity)/100000,2) as Total_sold_quantity_in_lakhs
FROM gdb023.fact_sales_monthly
where fiscal_year = 2020
group by Quarter
order by Total_sold_quantity_in_lakhs desc;
--------------------------------------------------------------------------------------------------------------------------------------
Request 9 :  Which channel helped to bring more gross sales in the fiscal year 2021 
 and the percentage of contribution?  The final output  contains these fields, 
 channel 
 gross_sales_mln 
 percentage 
 with cte as (
select a.channel as Channel,
round(sum(c.gross_price*b.sold_quantity)/1000000,2) as Gross_sales_mln

FROM gdb023.dim_customer AS a JOIN
    gdb023.fact_sales_monthly AS b ON
    a.customer_code = b.customer_code JOIN
    fact_gross_price AS c on 
    c.fiscal_year = b.fiscal_year and 
    c.product_code = b.product_code
where b.fiscal_year = 2021
group by Channel
order by Gross_sales_mln desc
)
,cte1 as (
select sum(Gross_sales_mln) as Total_gross_sales_mln
from cte
)
select cte.*,
round((Gross_sales_mln*100/Total_gross_sales_mln),2) as Percentage
from cte join cte1
-----------------------------------------------------------------------------------------------------------------------
Request 10 :  Get the Top 3 products in each division that have a high 
 total_sold_quantity in the fiscal_year 2021? The final output contains these 
 fields, 
 division 
 product_code 
 product 
 total_sold_quantity 
 rank_order 

with cte as (
SELECT a.division AS Division,
a.product_code AS Product_code,
a.product as Product,
sum(b.sold_quantity) as Total_sold_quantity,
a.variant as Variant
FROM gdb023.dim_product AS a INNER JOIN  gdb023.fact_sales_monthly AS b ON
a.product_code = b.product_code
WHERE b.fiscal_year = 2021
GROUP BY  Division, Product_code, a.product
),
cte1 as (
SELECT *,
DENSE_RANK() OVER (PARTITION BY Division ORDER BY Total_sold_quantity DESC) AS Rank_Order
from  cte
)
select * 
from cte1
where Rank_Order <=3;
 --------------------------------end of file-----------------------------------------------------------------------------
