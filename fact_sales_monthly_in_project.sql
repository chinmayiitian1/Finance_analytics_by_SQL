## adding 4 month to the date column so that we can convert it into the fiscal year
SELECT * FROM gdb0041.fact_sales_monthly
where customer_code=90002002 and
year(date_add(date,interval 4 month))=2021
order by date desc;
## in the above formula that is used for changing into the fiscal year that is big ,co we can use a user defined function 
## go the function
SELECT * FROM gdb0041.fact_sales_monthly
where 
     customer_code=90002002 and
	 get_fiscal_year(date)=2021 and 
     get_fiscal_quarter(date)="Q4"
order by date desc;

##  i want to show product name and variant also so i can do the joining opeartion
select
    s.date,s.product_code,s.sold_quantity,
    p.product,p.variant,g.gross_price,
    round(g.gross_price*s.sold_quantity,2)as gross_price_total
from gdb0041.fact_sales_monthly as s 
join gdb0041.dim_product as p
on p.product_code=s.product_code
join gdb0041.fact_gross_price as g
on   
     g.product_code=s.product_code and
     g.fiscal_year=get_fiscal_year(s.date)
where 
     customer_code=90002002 and 
     get_fiscal_year(date)=2021
order by date asc
limit 1000000;     

## do group by wrt date column

select s.date,sum(p.gross_price*s.sold_quantity)as total_gross_price
from gdb0041.fact_sales_monthly as s
join gdb0041.fact_gross_price as p
on s.product_code=p.product_code
  and p.fiscal_year=get_fiscal_year(s.date)
where s.customer_code=90002002  
group by s.date
order by s.date asc;





select * from gdb0041.dim_customer;
## generate a yearly report for chroma india where there are two columns 1- fiscal year 2-total gross sales amount in that year from india

select g.fiscal_year,sum(g.gross_price*s.sold_quantity) as total_gross_sales
from gdb0041.fact_sales_monthly as s
join gdb0041.dim_customer as c
on s.customer_code=c.customer_code
join gdb0041.fact_gross_price as g
on g.product_code=s.product_code and g.fiscal_year=get_fiscal_year(s.date)
where c.customer="croma" and c.market="India"
group by g.fiscal_year;


## let the company manager repeatadly ask the monthly_gross_sales_for_ diffrent customer then we want to make it automate
## we stored it in the stored procedure --you just enter the customer code then it  will shows the gross sales for that customer

## check into the stored_procedure
select s.date,sum(p.gross_price*s.sold_quantity)as total_gross_price
from gdb0041.fact_sales_monthly as s
join gdb0041.fact_gross_price as p
on s.product_code=p.product_code
  and p.fiscal_year=get_fiscal_year(s.date)
where s.customer_code=90002002  
group by s.date
order by s.date asc;


## this the stored procedure for when one customer code for a company
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_sales_customer`(
     c_code INT)
BEGIN
    select s.date,sum(p.gross_price*s.sold_quantity)as total_gross_price
    from gdb0041.fact_sales_monthly as s
    join gdb0041.fact_gross_price as p
    on s.product_code=p.product_code
        and p.fiscal_year=get_fiscal_year(s.date)
	where s.customer_code=c_code 
	group by s.date
	order by s.date asc;
END;

select * from gdb0041.dim_customer where  customer like "%amazon%" and market="India";
## we found there are two customer_code for the same customer --so we change the stored procedure so that it can take two customer code
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_sales_customer`(
     in_customer_code TEXT)
BEGIN
    select s.date,sum(p.gross_price*s.sold_quantity)as total_gross_price
    from gdb0041.fact_sales_monthly as s
    join gdb0041.fact_gross_price as p
    on s.product_code=p.product_code
        and p.fiscal_year=get_fiscal_year(s.date)
	where 
       FIND_IN_SET(s.customer_code,in_customer_code)>0
	group by s.date
	order by s.date asc;
END;
## it is running properly when we change the stored_procedure
select x.* from(with cte2 as (with cte1 as (SELECT c.region,c.market,(s.sold_quantity*p.gross_price) as total_price
FROM gdb0041.fact_sales_monthly as s
join gdb0041.dim_customer as c
on s.customer_code=c.customer_code 
join gdb0041.fact_gross_price as p
on s.product_code=p.product_code and s.fiscal_year=p.fiscal_year)
select region,market,sum(total_price) as gross_sales_1
from cte1
group by region,market)
select *,
rank() over(order by gross_sales_1) as rank_1
from cte2) as x
where x.rank_1<=2;

select y.*,
rank() over (order by y.total_quantity_1)as cvb from (
select x.division,x.product,
sum(x.total_quantity) over(partition by x.division,x.product ) as Total_quantity_1
from(
SELECT d.division,d.product,s.fiscal_year,s.sold_quantity,g.gross_price as gross_price_per_item,
s.sold_quantity*g.gross_price as total_price,
s.sold_quantity*g.gross_price total_quantity
FROM gdb0041.dim_product as d
join gdb0041.fact_sales_monthly as s
on d.product_code =s.product_code
join gdb0041.fact_gross_price as g
on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year) as x) as y;


use gdb0041;
select 
   p.division,
   p.product,
   sum(s.sold_quantity) as total_qty
from fact_sales_monthly as s
join dim_product as p
   on p.product_code=s.product_code
where fiscal_year=2021
group by p.product,p.division; 

SELECT * FROM gdb0041.net_sales;
use gdb0041;
with cte1 as (select 
     c.customer,
     c.region,
     round(sum(net_sales)/1000000,2) as net_sales_mln
  from net_sales as s
  join dim_customer as c
       on s.customer_code=c.customer_code
  where s.fiscal_year=2021
  group by c.customer,c.region)
select *,
    net_sales_mln*100/sum(net_sales_mln) over (partition by region) as pct_share_region
from cte1
order by region,net_sales_mln desc;

SELECT c.region,
net_sales*100/sum(net_sales) over(partition by c.region) as net_sales_mln
FROM gdb0041.net_sales as n
join gdb0041.dim_customer as  c
on n.customer_code=c.customer_code
where n.fiscal_year=2021 
group by c.customer,c.region
order by net_sales_mln desc
##basically first we do the sum operation
sum(net_sales)---net sales in milloins


select 
     c.customer,
     c.region,
     round(sum(net_sales)/1000000,2) as net_sales_mln
 from net_sales as s
 join dim_customer as c
       on s.customer_code=c.customer_code
where f.fiscal_year=2021
group by c.customer,c.region 

