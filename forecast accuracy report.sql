# As a product owner wants that aggregate forecast accuracy report for all the customers for a given---
# fiscal year ,so that they can track the accuracy of the forecast we make for these customers
# the report should have the following fields

# 1)customer_code, name,market     2)total sold quantity       3)total forecast quantity 
# 4) net error                      5) absolute error           6) forecast accuracy %

# fact_sales_monthly  / fact_forecast_monthly ---are having same columns one diff is sold quantity and forecast_quantity
# we are creating new table
------------------------------------------------------------------------------------------------------------
# fact _sales_month_count :1425706            # fact_forecast_monthly_count : 1885941
# inner join count: 1390837                   #  inner join count :1390837
# difference :34869                            #  difference :495104
-------------------------------------------------------------------------------------
# forecast    80   75  90 
# net error      30  -20  -10
#abs net error  30   20    10   => 60(abs net error)
# abs net error%   60/sum(forecast)----------60/80+75+90 = 24.49 %
# forecast accuracy  = 1-24.49% = 75.51%       


create table fact_act_estimates
(
   select
     s.date as date ,
     s.fiscal_year as fiscal_year ,
     s.product_code as product_code ,
     s.customer_code as customer_code,
     s.sold_quantity as sold_quantity,
     f.forecast_quantity as forecast_quantity
from fact_sales_monthly s
left join fact_forecast_monthly f
using(date, customer_code, product_code)

union

select
     f.date as date,
     f.fiscal_year as fiscal_year,
     f.product_code as product_code ,
     f.customer_code as customer_code,
     s.sold_quantity as sold_quantity,
     f.forecast_quantity as forecast_quantity
from  fact_forecast_monthly f
left join fact_sales_monthly s
using(date, customer_code, product_code)
);

---------------------------
SELECT * FROM gdb0041.fact_act_est;

update fact_act_est
set sold_quantity = 0
where sold_quantity is  null;
--------------------------------------
update fact_act_est
set forecast_quantity = 0
where forecast_quantity is  null;
------------------------------------------------
select 
    *,
    (forecast_quantity-sold_quantity) as net_error,
    abs(forecast_quantity-sold_quantity) as abs_error
from gdb0041.fact_act_est;
 
#------------%-------------------------------------------------------------
select 
    *,
    (forecast_quantity-sold_quantity) as net_error,
      (forecast_quantity-sold_quantity)*100/forecast_quantity as net_error_pct,
    abs(forecast_quantity-sold_quantity) as abs_error,
    abs(forecast_quantity-sold_quantity)*100/forecast_quantity as abs_error_pct
from gdb0041.fact_act_est;
#-----------------------------------------------------------------------------
# when we use group by we have to use aggregation 
select
customer_code,
   sum((forecast_quantity-sold_quantity)) as net_error,
     sum((forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as net_error_pct,
    sum(abs(forecast_quantity-sold_quantity)) as abs_error,
   sum(abs(forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as abs_error_pct
from gdb0041.fact_act_est s
where s.fiscal_year = 2021
group by customer_code
order by abs_error_pct desc ;

#------forecast_accuracy = 1-abs_error %---------- but we cant use derived column in directly in the select statement
# we have use cte
with forecast_err_table as(
select
   s.customer_code ,
   sum(s.sold_quantity) as total_sold_qty,
   sum(s.forecast_quantity) as total_forecast_qty,
   sum((forecast_quantity-sold_quantity)) as net_error,
     sum((forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as net_error_pct,
    sum(abs(forecast_quantity-sold_quantity)) as abs_error,
   sum(abs(forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as abs_error_pct
from gdb0041.fact_act_est s
where s.fiscal_year = 2021
group by customer_code)
select 
    e.* ,
    c.customer,
    c.market,
     if(abs_error_pct>100,0,100-abs_error_pct) as forecast_accuracy
from forecast_err_table e
join dim_customer c
using (customer_code)
order by forecast_accuracy desc





