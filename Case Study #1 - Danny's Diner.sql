CREATE DATABASE dannys_diner;
USE dannys_diner;


CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
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
  product_id INT,
  product_name VARCHAR(5),
  price INT
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

DROP DATABASE dannys_diner;


select * from sales;

-- What is the total amount each customer spent at the restaurant?
select  s.customer_id, sum(m.price) as total_amount_spent   from sales s
join menu m on m.product_id=s.product_id
group by s.customer_id;

-- How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) from sales
group by customer_id;


-- What was the first item from the menu purchased by each customer?
with cte as (select customer_id, product_id, row_number() over(partition by customer_id order by order_date asc) as r
from sales)
select customer_id, product_id from cte
where r = 1;


-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_id, count(product_id) as total_count
from sales
group by product_id
order by 2 desc
limit 1;


-- Which item was the most popular for each customer?
WITH cte AS (
    SELECT customer_id, product_id, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS r
    FROM sales
    GROUP BY customer_id, product_id
)
SELECT 
    c.customer_id, m.product_name AS most_popular_item
FROM cte c
JOIN menu m ON c.product_id = m.product_id
WHERE c.r = 1;

-- Which item was purchased first by the customer after they became a member?
with cte as  (select s.customer_id, s.product_id, s.order_date, m.join_date,  rank() over(partition by s.customer_id order by s.order_date asc)as r
from sales s
join members m on m.customer_id= s.customer_id 
where order_date >= join_date
)
select customer_id, product_id 
from cte
where r  = 1;




-- Which item was purchased just before the customer became a member?
with cte as  (select s.customer_id, s.product_id, s.order_date, m.join_date,  rank() over(partition by s.customer_id order by s.order_date desc)as r
from sales s
join members m on m.customer_id= s.customer_id 
where order_date < join_date
)
select customer_id, product_id 
from cte
where r  = 1;

-- What is the total items and amount spent for each member before they became a member?
with cte as  (select s.customer_id , me.price ,rank() over(partition by s.customer_id order by s.order_date desc)as r
from sales s
left join members m on m.customer_id= s.customer_id 
left join menu me on me.product_id=s.product_id
where order_date < join_date

)

select customer_id , sum(price) from cte
group by customer_id;



-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as  (select s.customer_id,  case when s.product_id = 1 then m.price *20 else m.price *10  end as points  from sales s
join menu m on m.product_id = s.product_id)


select customer_id, sum(points)
from cte
group by customer_id;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as  (select s.customer_id, s.order_date,  case when s.product_id = 1 then m.price *20 
										when   s.product_id = 2 then m.price *10 
                                        when   s.product_id = 2 then m.price *10 
                                        when   me.join_date >= s.order_date then m.price *20 end as points 
from sales s
join menu m on m.product_id = s.product_id
join members me on me.customer_id=s.customer_id)

select customer_id, sum(points)
from cte
where  order_date <  "2021-02-01"
group by 1


