/*
Project: E-commerce Funnel Analysis
Database: Microsoft SQL Server
Purpose: Analyze user progression, conversion rates,
traffic-source performance, conversion time, and revenue.
*/

SELECT TOP (1000) [event_id]
      ,[user_id]
      ,[event_type]
      ,[event_date]
      ,[product_id]
      ,[amount]
      ,[traffic_source]
  FROM dbo.[SQL Mini Project];
  
  -- define sales funnel and the different stages
  -- Start with a CT (CT means Common Table EXpression)

  WITH date_range AS (
  SELECT MAX(event_date) AS max_event_date
  FROM dbo.[SQL Mini Project]),
  
  funnel_stages AS (

  SELECT -- to count the user id's that are going thru the diff stages
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
  COUNT (DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
  COUNT (DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase

  FROM dbo.[SQL Mini Project]

  WHERE event_date >= DATEADD(DAY, -30, (SELECT max_event_date FROM  date_range))  /*to select the
  last 30 days */
  )
  
  SELECT * FROM funnel_stages;


  -- Conversion rate through the funnel
   WITH date_range AS (
  SELECT MAX(event_date) AS max_event_date
  FROM dbo.[SQL Mini Project]),
  
  funnel_stages AS (

  SELECT -- to count the user id's that are going thru the diff stages
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
  COUNT (DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
  COUNT (DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase

  FROM dbo.[SQL Mini Project]

  WHERE event_date >= DATEADD(DAY, -30, (SELECT max_event_date FROM  date_range))  /*to select the
  last 30 days */
  )
  
  SELECT 
  stage_1_views,
  stage_2_cart,
  ROUND(stage_2_cart * 100.0 / stage_1_views, 2) AS view_to_cart_rate,

  stage_3_checkout,
  ROUND(stage_3_checkout * 100.0 / stage_2_cart, 2) AS cart_to_checkout_rate,

  stage_4_payment,
  ROUND(stage_4_payment * 100.0 / stage_3_checkout, 2) AS checkout_to_payment_rate,

  stage_5_purchase,
  ROUND(stage_5_purchase * 100.0 / stage_4_payment, 2) AS payment_to_purchase_rate,

  ROUND(stage_5_purchase * 100.0 / stage_1_views, 2) AS overall_conversion_rate
  
  FROM funnel_stages;


  --- funnel by source, traffic source of people coming into the site
  WITH date_range AS (
  SELECT MAX(event_date) AS max_event_date
  FROM dbo.[SQL Mini Project]),

  source_funnel AS(
  
  SELECT
  traffic_source,
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
  COUNT (DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS purchases

  FROM dbo.[SQL Mini Project]
  
  WHERE event_date >= DATEADD(DAY, -30, (SELECT max_event_date FROM  date_range))
  GROUP BY traffic_source
  )
  SELECT
  traffic_source,
  views,
  carts,
  purchases,
  ROUND(carts * 100.0 /views, 2) AS cart_coversation_rate,
  ROUND(purchases * 100.0 /views, 2) AS purchase_coversation_rate,
  ROUND(purchases * 100.0 /views, 2) AS cart_to_purchase_coversation_rate

  FROM source_funnel
  ORDER BY purchases DESC;

  --- time to conversion analysis, time spent by customers in the funnel stages

  WITH date_range AS (
  SELECT MAX(event_date) AS max_event_date
  FROM dbo.[SQL Mini Project]),

  user_journey AS(
  
  SELECT
  user_id,
  MIN (DISTINCT CASE WHEN event_type = 'page_view' THEN event_date END) AS view_time,
  MIN (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
  MIN (DISTINCT CASE WHEN event_type = 'purchase' THEN event_date END) AS purchase_time

  FROM dbo.[SQL Mini Project]
  
  WHERE event_date >= DATEADD(DAY, -30, (SELECT max_event_date FROM  date_range))
  GROUP BY user_id
  HAVING MIN( CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
  )
  SELECT
  COUNT(*) AS converted_users,
  ROUND(AVG(CAST(DATEDIFF(MINUTE, view_time, cart_time) AS FLOAT)), 2) AS avg_view_to_cart_minutes,
  --USE CAST() TO GET DECIMA PLACE
  ROUND(AVG(DATEDIFF(MINUTE, cart_time, purchase_time)), 2) AS avg_cart_to_purchase_minutes,
  ROUND(AVG(DATEDIFF(MINUTE, view_time, purchase_time)), 2) AS avg_total_journey_minutes
  FROM user_journey;

  -- REVENUE FUNNEL ANALYSIS
  WITH date_range AS (
  SELECT MAX(event_date) AS max_event_date
  FROM dbo.[SQL Mini Project]),

  funnel_revenue AS(
  
  SELECT
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_buyers,
  SUM (CASE WHEN event_type = 'purchase' THEN amount END) AS total_revenue,
  COUNT (CASE WHEN event_type = 'purchase' THEN 1 END) AS total_orders
  FROM dbo.[SQL Mini Project]
  
  WHERE event_date >= DATEADD(DAY, -30, (SELECT max_event_date FROM  date_range))
  
  )

  SELECT 
  total_visitors,
  total_buyers,
  total_revenue,
  total_orders,
  total_revenue/total_orders AS avg_order_value,
  total_revenue/total_buyers AS revenue_per_buyer,
  total_revenue/total_visitors AS revenue_per_visitor
  
  FROM funnel_revenue;  