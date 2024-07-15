create database dannys_diner;
use dannys_diner;
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  
  -- select all tables 
  select * from members;
  select * from menu;
  select * from sales;
  
  
-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as total_price
from menu m
join sales s
on s.product_id=m.product_id
group by  customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date)
from sales
group by customer_id
order by customer_id desc;
-- What was the first item from the menu purchased by each customer?
with first_item as
(
select s.customer_id, m.product_name,
row_number() over(partition by s.customer_id
order by s.order_date, s.product_id) as item_ordered
from sales s
join menu m
on s.product_id=m.product_id
)
select * from first_item
where item_ordered=1;

-- What is the most purchased item on the menu and how many times was it purchased by
-- all customers?
select s.product_id, count(m.product_id) as purchased_item ,m.product_name
from sales s
join menu m 
on s.product_id=m.product_id
group by product_id, m.product_name
order by purchased_item desc
limit 1;

-- 5. Which item was the most popular for each customer?
with CTE AS
(
SELECT s.customer_id,m.product_name, count(*) as order_count
FROM sales s
JOIN menu m
on s.product_id=m.product_id
group by s.customer_id,m.product_name
order by order_count, s.customer_id desc
),
cte_popular_rank as 
(  select *, rank() over(partition by customer_id order by order_count
) as ranks
from CTE)
select * from cte_popular_rank 
where ranks=1;

-- 6. Which item was purchased first by the customer after they became a member? 
select s.customer_id, min(s.order_date) as first_order,m.product_name
from menu m
inner join sales s
on m.product_id= s.product_id
join  members mem
on s.customer_id=mem.customer_id
where s.order_date> mem.join_date
group by s.customer_id,m.product_name
order by s.customer_id,min(s.order_date);

-- 7. Which item was purchased just before the customer became a member?

select s.customer_id, max(s.order_date) as first_order,m.product_name
from menu m
inner join sales s
on m.product_id= s.product_id
join  members mem
on s.customer_id=mem.customer_id
where s.order_date< mem.join_date
group by s.customer_id,m.product_name
order by s.customer_id,max(s.order_date);


-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(m.product_name) as Total_Item, sum(price) as Total_amount
from sales s
inner join menu m
on s.product_id=m.product_id
join members mem
on s.customer_id=mem.customer_id
where 
s.order_date<mem.join_date
group by s.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier—how many
-- points would each customer have?


with point_count_CTE as
(
Select s.customer_id,m.product_name,
CASE
WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
            ELSE m.price * 10
        END AS points
from sales s
inner join menu m
on s.product_id=m.product_id

)

SELECT
    customer_id,product_name,
    SUM(points) AS total_points
FROM
    point_count_CTE
GROUP BY
    customer_id,product_name;
-- 10. In the first week after a customer joins the program (including their join date) they earn
-- 2x points on all items, not just sushi—how many points do customer A and B have at the
-- end of January?

With Points_CTE AS
(
SELECT S.customer_id,m.price,
CASE
WHEN m.product_name='sushi' THEN m.price * 10 * 2
            ELSE m.price * 10
        END AS normal_points,
CASE
WHEN S.order_date between mem.join_date AND date(join_date+7) THEN m.price * 10 * 2
            ELSE 0
        END AS first_week_points
        
from sales s
inner join menu m
on s.product_id=m.product_id
join members mem
on s.customer_id=mem.customer_id
WHERE
        s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
)

select
  customer_id,
  SUM(
        CASE
            WHEN first_week_points > 0 THEN first_week_points
            ELSE normal_points
        END
    ) AS total_points
FROM
    Points_CTE
GROUP BY
    customer_id;
    -- Bonus Questions
-- Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use
-- to quickly derive insights without needing to join the underlying tables using SQL.
Select s.customer_id,s.order_date,m.product_name,m.price,
CASE
WHEN mem.customer_id IS NOT NULL AND S.order_date>=mem.join_date then "Y"
ELSE "N"
END AS member

from sales s
inner join menu m
on s.product_id=m.product_id
join members mem 
on s.customer_id=mem.customer_id
order by s.customer_id,s.order_date;

-- Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he
-- purposely does not need the ranking for non-member purchases so he expects null ranking
-- values for the records when customers are not yet part of the loyalty program.
Select s.customer_id,s.order_date,m.product_name,m.price,
CASE
WHEN mem.customer_id IS NOT NULL AND S.order_date>=mem.join_date then "Y"
ELSE "N"
END AS member,
CASE
            WHEN mem.customer_id IS NOT NULL AND s.order_date >= mem.join_date THEN
                RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date, s.product_id)
            ELSE NULL
        END AS ranks
from sales s
inner join menu m
on s.product_id=m.product_id
join members mem 
on s.customer_id=mem.customer_id
order by s.customer_id,s.order_date;