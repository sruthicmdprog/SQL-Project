
		 
---------------------------------------------------------------------------------------------------------------------------
   use gdb0041;
 
   select * from fact_sales_monthly
   where customer_code = 90002002
 
 ------------------------------------------------------------------------------------------------------------------------
 # As A Product owner requriment , we want to generate a report of individual Product sales(Aggregated on a monthly basis at the product code level)
 # for croma india customer for FY = 2021 so that we can track individual product sales and run further product analytics on it in excel.
 
 # Month
 # Product Name
 # Variant
 # Sold Quantity
 # Gross price per item
 # Gross per total
 -----------------------------------------------------------------------------------------------------------------------------
   select * from fact_sales_monthly
   where customer_code = 90002002 and year(date) = 2021
   order by date desc
 ---------------------------------------------------------------------------  
   # We need to convert calendar year date to fiscal  year date 
    #09-2020 -> 01-2021
    # 10-2020 -> 02-2021
    -----------------------------------------------------------------------------------------
 # we are adding 4 months to calendar date because the Atliq company fiscal year starts from september
  # we have created get_fiscal_year is a created function 
  ------------------------------------------------------------------------------------------------------------------ 
   select * from fact_sales_monthly
   where customer_code = 90002002 and
   get_fiscal_year(date) = 2021 and
    get_fiscal_quarter(date) = "q4"
   order by date asc
  
-----------------------------
   #  we want to add quarters
# 9,10,11  -> q1
# 12,1,2  ->  q2
# 3,4,5  ->  q3
# 6,7,8 ->   q4

select MONTH("2020-09-01") --------------> this function tells the month
# we created get_fiscal_quarter function
 -------------------------------------------------------------------------------------
 select s.date,s.product_code,p.product,p.variant,s.sold_quantity
 from fact_sales_monthly s
 join dim_product p
 on p.product_code = s.product_code
   where customer_code = 90002002 and
   get_fiscal_year(date) = 2021 
  order by date asc
 ----------------------------------------------------------------------------
 # gross_price
 
  select s.date,s.product_code,p.product,p.variant,s.sold_quantity,g.gross_price 
  from fact_sales_monthly s
 join dim_product p
 on p.product_code = s.product_code
 join fact_gross_price g
 on g.product_code = s.product_code and
 g.fiscal_year = get_fiscal_year(s.date)
   where customer_code = 90002002 and
   get_fiscal_year(date) = 2021 
  order by date asc

 --------------------------------------------------------------------------------------------------------------
 # gross_price_total
 
  select s.date,s.product_code,p.product,p.variant,s.sold_quantity,g.gross_price,
  ROUND(g.gross_price*s.sold_quantity,2) as gross_price_total
  from fact_sales_monthly s
 join dim_product p
 on p.product_code = s.product_code
 join fact_gross_price g
 on g.product_code = s.product_code and
 g.fiscal_year = get_fiscal_year(s.date)
   where customer_code = 90002002 and
   get_fiscal_year(date) = 2021 
  order by date asc
-------------------------------------------------------------------------------------------------------------------------------
  # As A Product owner requriment , we need aggregate monthly gross sales report for croma india customer , so that can track how much sales
  # this particular customer is generating for Atliq abd manage our relationships accordingly.
  # The report should have 
      # Month
      # Total gross sales amount to croma india in this month 
# croma_monthly_total_sales
select s.date , sum(g.gross_price*s.sold_quantity) as gross_price_total
from fact_sales_monthly s
join fact_gross_price g
on g.product_code = s.product_code and
   g.fiscal_year = get_fiscal_year(s.date)
where customer_code = 90002002
group by s.date 
order by s.date asc
-------------------------------------------------------------------------------------------------------------------------

#1) Generate a yearly report for Croma India where there are two columns
	#1. Fiscal Year
	#2. Total Gross Sales amount In that year from Croma
         
         select
            get_fiscal_year(date) as fiscal_year,
            sum(round(sold_quantity*g.gross_price,2)) as yearly_sales
	from fact_sales_monthly s
	join fact_gross_price g
	on 
	    g.fiscal_year=get_fiscal_year(s.date) and
	    g.product_code=s.product_code
	where
	    customer_code=90002002
	group by get_fiscal_year(date)
	order by fiscal_year;
-----------------------------------------------------------------------------------------------------------------------
# Stored procedure is a way to automate repeated tasks such as creating the same report for different customers.
# The query that needs to be executed in a stored procedure is copied between BEGIN and END clause.
# One can enter multiple values as input to run a query and retrieve an aggregated report.
----------------------------------------------------------------------------------------------------------------------
# in stored procedure we have used find_in_select for 2 or more entries
select find_in_set(90002002,"90002002,90002008")
# the position of 90002002 is in 1st position 
-----------------------------------------------------------------------------------------------------------
---------# market / total_quantity -------------------------------;

 select 
	c.market,
     sum(sold_quantity)as total_qty
 from fact_sales_monthly s
 join dim_customer c
 on s.customer_code = c.customer_code
 where get_fiscal_year(s.date) = 2021
 group by c.market

----------------------------------------------------------------------------------------------------------------------
# create a stored proc that can determine the market badge based on the following logic
  # if total sold quantity > 5 million that market is considered gold else it is silver 
  # input          # output
  # market         # Market badge
  # fiscal_year
  
  #(we have created stored procedure ( get_market_badge)
-------------------------------------------------------------------------------------------------------------------
             # Gross price
         #    -pre invoice deduction
	-----------------------------------
          #  = Net invoice sales
		#   - Post invoice deduction
	-------------------------------------
      #     = Net sales = (revenue)      
  --------------------------------------------------------------------------------------------------           
   # Pre invoice ----------------------          
             
select s.date,s.product_code,p.product,p.variant,s.sold_quantity,g.gross_price as gross_price_per_item,
ROUND(g.gross_price*s.sold_quantity,2)as gross_price_total, pre.pre_invoice_discount_pct
from fact_sales_monthly s
 join dim_product p
 on p.product_code = s.product_code
 join fact_gross_price g
 on g.product_code = s.product_code and
    g.fiscal_year = get_fiscal_year(s.date)
 join fact_pre_invoice_deductions pre 
 on pre.customer_code = s.customer_code AND
    pre.fiscal_year = get_fiscal_year(s.date)
where 
   get_fiscal_year(date) = 2021
  limit 1000000;   
----------------------------------------------------------------------------------------             
# but it has taking long time to run ----- we have to improve performance 
# to improve the performance we are creating dim_date table 
             
select s.date,s.product_code,p.product,p.variant,s.sold_quantity,g.gross_price as gross_price_per_item,
ROUND(g.gross_price*s.sold_quantity,2)as gross_price_total,
pre.pre_invoice_discount_pct
  from fact_sales_monthly s
 join dim_product p
 on p.product_code = s.product_code
 join dim_date dt
   on dt.calendar_date = s.date
 join fact_gross_price g
 on g.product_code = s.product_code and
    g.fiscal_year = dt.fiscal_year
 join fact_pre_invoice_deductions pre 
 on pre.customer_code = s.customer_code AND
    pre.fiscal_year =dt.fiscal_year
where 
   dt.fiscal_year = 2021
  limit 1000000;            
-------------------------------------------------------------------------------------------------------
# dim_table is also taking some time to execute             
# instead of using dim_date table we have created the fiscal_year in fact_sales_monthly table 
# we replace dt.fiscal_year = s.fiscal_year
WITH cte1 as 
       (select s.date,s.product_code,p.product,p.variant,s.sold_quantity,g.gross_price as gross_price_per_item,
ROUND(g.gross_price*s.sold_quantity,2)as gross_price_total,
pre.pre_invoice_discount_pct
  from fact_sales_monthly s
 join dim_product p
 on s.product_code = p.product_code
 join fact_gross_price g
 on g.product_code = s.product_code and
    g.fiscal_year = s.fiscal_year
 join fact_pre_invoice_deductions pre 
 on pre.customer_code = s.customer_code AND
    pre.fiscal_year =s.fiscal_year
where 
   s.fiscal_year = 2021)
 select *,
      (gross_price_total - gross_price_total * pre_invoice_discount_pct) as net_invoice_sales
      from cte1;
      # cte is much complicated in this situation
 --------------------------------------------------------------------------------------------------
# NOW  we want to join post_invoice_discount_pct  from that (net_invoice_sales-post_invoice we will get NET SALES)
# for that we want to use one more cte is was much complicated so we have  to use VIEWS 
# we have created a view   (sales_preinv_discount)
 select *,
      (gross_price_total - gross_price_total * pre_invoice_discount_pct) as net_invoice_sales
      from sales_preinv_discount;
      
#-----------post_invoice_ded---------------------

select
     *,
     (1-pre_invoice_discount_pct) * gross_price_total as net_invoice_sales,
     (po.discounts_pct + po.other_deductions_pct)as post_invoice_discount_pct
from sales_preinv_discount s
join fact_post_invoice_deductions po
on
s.date = po.date and
s.product_code = po.product_code and
s.customer_code = po.customer_code

# created sales_postinv_discount view
-------------------------------
# net sales
 select 
      *,
    (1- post_invoice_discount_pct)*net_invoice_sales as net_sales
from sales_postinv_discount;

---------------------# created view on NET_SALES-----------------------------------------
------------------------------------------------------------------------------------------------------
# example
1) Create a view for gross sales. It should have the following columns,
    date, fiscal_year, customer_code, customer, market, product_code, product, variant,
	sold_quanity, gross_price_per_item, gross_price_total
----------------------------------------------------------------------------------------------------------    
#----------------------# TOP MARKET#-----------------------------------------------
	
select market, round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales
where fiscal_year = 2020
group by market
order by net_sales_mln desc
limit 4;

#--------------TO REUSE WE HAVE CREATED THE STORED PROCEDURE ON TOP MARKETS---------------- 


#--------------------TOP CUSTOMER------------------------------------

select c.customer,round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales n
join dim_customer c
on n.customer_code = c.customer_code
where fiscal_year = 2021
group by c.customer
order by net_sales_mln desc
limit 5;
#-------------------TO REUSE WE HAVE CREATED THE STORED PROCEDURE ON TOP CUSTOMERS-----------------------------

#--------------------------TOP PRODUCTS---------------------------
1) Write a stored procedure to get the top n products by net sales for a given year.  
   Use product name without a variant. Input of stored procedure is fiscal_year and top_n parameter


	CREATE PROCEDURE get_top_n_products_by_net_sales(
              in_fiscal_year int,
              in_top_n int
	)
	BEGIN
            select
                 product,
                 round(sum(net_sales)/1000000,2) as net_sales_mln
            from gdb041.net_sales
            where fiscal_year=in_fiscal_year
            group by product
            order by net_sales_mln desc
            limit in_top_n;
	END
--------------------------------------------------------------------------------------------------
# NET SALES % SHARE GLOBAL
# As a product wants to see a bar chart report  for FY = 2021 for top 10 markets by % net sales 
# to created a bar chart report we have used excel
# they have asked for only 2021 but we have to create for query just changing the year ,

with cte1 as
(select customer,round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
join dim_customer c
on s.customer_code = c.customer_code
where s.fiscal_year = 2021
group by customer)
select 
   *,
   net_sales_mln*100/sum(net_sales_mln) over() as pct
   from cte1
order by net_sales_mln desc
--------------------------------------------------------------------------------------------
# ------------NET SALES % SHARE BY REGION-----------------
# As a product he wants to see region wise(APAC,EU,LTAM etc) % net sales breakdown by customers in the respective
# region so that they can perform regional analysis on financial performance of the company 


with cte1 as
(select c.customer,
       c.region,
      round(sum(net_sales)/1000000,2) as net_sales_mln
	  from net_sales s
      join dim_customer c
      on s.customer_code = c.customer_code
      where s.fiscal_year = 2021
      group by c.customer,c.region)
select
     *,
   net_sales_mln*100/sum(net_sales_mln) over(partition by region) as pct_share_region
   from cte1
order by region, net_sales_mln desc
      
# explanation: APAC :  amazon:57.41
			# total of APAC:442             57.41*100/442 = 12.98868
---------------------------------------------------------------------------------------------------
  # TOP N PRODUCTS in each division by their quality sold    
  with cte1 as 
    (select 
	    p.division,
        p.product,
     sum(sold_quantity)as total_qty
 from fact_sales_monthly s
 join dim_product p
 on p.product_code = s.product_code
 where fiscal_year = 2021
 group by p.product,p.division),
 cte2 as(select
          *,
          dense_rank() over(partition by division order by total_qty desc) as drnk
          from cte1)
select * from cte2 where drnk<=3

# explanation cte2 ?   drnk<=3 we can't write in the derived column so we have created cte 2 
#----------------------------we have created stored procedure for top products-------------------------


1) Retrieve the top 2 markets in every region by their gross sales amount in FY=2021.


	with cte1 as (
		select
			c.market,
			c.region,
			round(sum(gross_price_total)/1000000,2) as gross_sales_mln
			from gross_sales s
			join dim_customer c
			on c.customer_code=s.customer_code
			where fiscal_year=2021
			group by c.market,c.region
			order by gross_sales_mln desc
		),
		cte2 as (
			select *,
			dense_rank() over(partition by region order by gross_sales_mln desc) as drnk
			from cte1
		)
	select * from cte2 where drnk<=2
		







