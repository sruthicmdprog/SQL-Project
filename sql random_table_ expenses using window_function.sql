# we have import the random_tables data

use random_tables;
select * from expenses order by category;
select * from student_marks;

select sum(amount) from expenses; # 65800
#----------------%------------------
select
	*,
   amount*100/sum(amount) over() as pct
   from random_tables.expenses
    order by category;
    ------------------------------------------------------------------------------------
    #------ we are getting one row  but we want the total columns so we have used the window function   OVER()--------------------
    
    # total per category  6000*100/11800=50.84 (11800 = total amount of food)
 select *,
      amount*100/ (sum(amount)over(partition by category)) as pct
       from random_tables.expenses
    order by category;  
 --------------------------------------------------------------------------------------------------
 # cumulative sum : increasing by one addition after another and including all the amounts that have been added before
 
 select 
      *,
      sum(amount)
      over(partition by category order by date) as total_expense_till_date
      from expenses
      order by category,date ;
  ----------------------------------------------------------------------------------------------    
  # RANK ,   ROW_NUMBER  , DENSE_RANK
  
  select
      *,
      row_number() over(order by marks desc) as rn,
      rank() over(order by marks desc) as rnk,
      dense_rank() over(order by marks desc) as drnk
from student_marks;
    
---------------------------------------------------------------------------------    
    
    