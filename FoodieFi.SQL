-- https://8weeksqlchallenge.com/case-study-3/
-- Part A (Customer Journey)
SELECT 
  * 
FROM 
  SUBSCRIPTIONS S 
  JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
ORDER BY 
  CUSTOMER_ID, 
  START_DATE;
-- Part B (Data Analysis Questions)
-- 1. How many customers has Foodie-Fi ever had?
SELECT 
  COUNT(DISTINCT CUSTOMER_ID) 
FROM 
  SUBSCRIPTIONS;
-- ANS: 1000
-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT 
  MONTH(START_DATE) AS Month_Trial_Starting, 
  COUNT(DISTINCT CUSTOMER_ID) 
FROM 
  SUBSCRIPTIONS S 
  JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
WHERE 
  P.PLAN_ID = 1 
GROUP BY 
  Month_Trial_Starting 
ORDER BY 
  Month_Trial_Starting;
-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT 
  PLAN_NAME, 
  COUNT(START_DATE), 
  DATE_PART(YEAR, START_DATE) AS Subscription_Year 
FROM 
  SUBSCRIPTIONS S 
  JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
WHERE 
  Subscription_Year > 2020 
GROUP BY 
  PLAN_NAME, 
  Subscription_Year 
ORDER BY 
  PLAN_NAME, 
  Subscription_Year;
-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH Total AS (
  SELECT 
    'Link' AS Link, 
    COUNT(DISTINCT CUSTOMER_ID) AS Total_Customers 
  FROM 
    SUBSCRIPTIONS
), 
Churned AS (
  SELECT 
    'Link' AS Link, 
    COUNT(DISTINCT CUSTOMER_ID) AS Total_Churn 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  WHERE 
    PLAN_NAME = 'churn'
) 
SELECT 
  ROUND(
    Total_Churn / Total_Customers * 100, 
    1
  ) AS Percent_Churned 
FROM 
  CHURNED c 
  JOIN TOTAL t ON c.Link = t.Link;
-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH Plan_Table AS (
  SELECT 
    ROW_NUMBER() OVER(
      PARTITION BY S.CUSTOMER_ID 
      ORDER BY 
        S.PLAN_ID ASC
    ) AS Plan_Order, 
    CUSTOMER_ID, 
    S.PLAN_ID, 
    START_DATE, 
    PLAN_NAME, 
    PRICE 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  ORDER BY 
    CUSTOMER_ID, 
    START_DATE
), 
Total AS (
  SELECT 
    'Link' AS Link, 
    COUNT(DISTINCT CUSTOMER_ID) AS Total_Customers 
  FROM 
    SUBSCRIPTIONS
), 
Churned_after_trial AS (
  SELECT 
    COUNT(PLAN_ID) AS Churned_following_trial, 
    'Link' AS Link 
  FROM 
    PLAN_TABLE 
  WHERE 
    Plan_Order = 2 
    AND PLAN_ID = 4
) 
SELECT 
  Churned_following_trial, 
  ROUND(
    Churned_following_trial / Total_Customers * 100, 
    1
  ) AS PercentOfTotal_Churned_After_Trial 
FROM 
  CHURNED_AFTER_TRIAL c 
  JOIN TOTAL t ON t.Link = t.Link;
-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH Plan_Table AS (
  SELECT 
    ROW_NUMBER() OVER(
      PARTITION BY S.CUSTOMER_ID 
      ORDER BY 
        S.PLAN_ID ASC
    ) AS Plan_Order, 
    CUSTOMER_ID, 
    S.PLAN_ID, 
    START_DATE, 
    PLAN_NAME, 
    PRICE, 
    'Link' AS Link 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  ORDER BY 
    CUSTOMER_ID, 
    START_DATE
), 
Plans_after_free_trial AS (
  SELECT 
    'Link' AS Link, 
    COUNT(DISTINCT CUSTOMER_ID) AS Total_on_plans 
  FROM 
    PLAN_TABLE 
  WHERE 
    Plan_Order = 2 
    AND Plan_ID != 4
) 
SELECT 
  'Link' AS Link, 
  PLAN_NAME, 
  COUNT(DISTINCT CUSTOMER_ID) AS Number_on_plan, 
  MAX(Total_on_plans) AS Total_on_plan, 
  ROUND(
    (Number_on_plan / Total_on_plan)* 100, 
    1
  ) AS Percentage_on_plan_straight_after_trial 
FROM 
  PLAN_TABLE p 
  JOIN PLANS_AFTER_FREE_TRIAL a ON p.Link = a.Link 
WHERE 
  Plan_Order = 2 
  AND Plan_ID != 4 
GROUP BY 
  PLAN_NAME;
-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH Plans_before_date AS (
  SELECT 
    ROW_NUMBER() OVER(
      PARTITION BY S.CUSTOMER_ID 
      ORDER BY 
        S.PLAN_ID ASC
    ) AS Plan_Order, 
    CUSTOMER_ID, 
    S.PLAN_ID, 
    START_DATE, 
    PLAN_NAME 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  WHERE 
    START_DATE <= DATE_FROM_PARTS(2020, 12, 31) 
  ORDER BY 
    CUSTOMER_ID, 
    START_DATE
), 
Customer_max AS (
  SELECT 
    'Link' as Link, 
    CUSTOMER_ID, 
    MAX(PLAN_ORDER) AS Customer_stage 
  FROM 
    PLANS_BEFORE_DATE 
  GROUP BY 
    CUSTOMER_ID
), 
Total_on_date AS (
  SELECT 
    'Link' as Link, 
    COUNT(c.CUSTOMER_ID) AS total 
  FROM 
    CUSTOMER_MAX c 
    LEFT JOIN PLANS_BEFORE_DATE p ON c.customer_id = p.customer_id 
    AND c.customer_stage = p.plan_order
) 
SELECT 
  p.PLAN_NAME, 
  COUNT(c.CUSTOMER_ID) AS total_per_plan, 
  MAX(t.total) AS Total, 
  ROUND(
    (
      Total_Per_Plan / MAX(t.total)
    ) * 100, 
    1
  ) AS Percentage_Breakdown 
FROM 
  CUSTOMER_MAX c 
  LEFT JOIN PLANS_BEFORE_DATE p ON c.customer_id = p.customer_id 
  AND c.customer_stage = p.plan_order 
  JOIN total_on_date t ON t.Link = c.Link 
GROUP BY 
  PLAN_NAME;
-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT 
  COUNT(CUSTOMER_ID) AS Plans_starting_2020, 
  PLAN_NAME 
FROM 
  SUBSCRIPTIONS S 
  JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
WHERE 
  YEAR(START_DATE) = 2020 
  AND CONTAINS(PLAN_NAME, 'annual') 
GROUP BY 
  PLAN_NAME;
-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH Customer_class_dates AS (
  SELECT 
    s.customer_id, 
    MIN(START_DATE) AS Date_joined 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  GROUP BY 
    CUSTOMER_ID 
  ORDER BY 
    CUSTOMER_ID
), 
Annual_plan_start AS (
  SELECT 
    s.customer_id, 
    MIN(START_DATE) AS Date_Annual_Started 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  WHERE 
    PLAN_NAME = 'pro annual' 
  GROUP BY 
    CUSTOMER_ID 
  ORDER BY 
    CUSTOMER_ID
), 
Time_to_annual AS (
  SELECT 
    c.customer_id, 
    Date_annual_started, 
    Date_joined, 
    DATEDIFF(
      DAY, date_joined, date_annual_started
    ) AS avg_time_taken 
  FROM 
    ANNUAL_PLAN_START a 
    INNER JOIN CUSTOMER_CLASS_DATES c ON a.CUSTOMER_ID = c.CUSTOMER_ID
) 
SELECT 
  AVG (avg_time_taken) 
FROM 
  TIME_TO_ANNUAL;
-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH Customer_class_dates AS (
  SELECT 
    s.customer_id, 
    MIN(START_DATE) AS Date_joined 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  GROUP BY 
    CUSTOMER_ID 
  ORDER BY 
    CUSTOMER_ID
), 
Annual_plan_start AS (
  SELECT 
    s.customer_id, 
    MIN(START_DATE) AS Date_Annual_Started 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  WHERE 
    PLAN_NAME = 'pro annual' 
  GROUP BY 
    CUSTOMER_ID 
  ORDER BY 
    CUSTOMER_ID
), 
Time_to_annual AS (
  SELECT 
    c.customer_id, 
    Date_annual_started, 
    Date_joined, 
    DATEDIFF(
      DAY, date_joined, date_annual_started
    ) AS time_taken 
  FROM 
    ANNUAL_PLAN_START a 
    INNER JOIN CUSTOMER_CLASS_DATES c ON a.CUSTOMER_ID = c.CUSTOMER_ID
), 
Categorised AS (
  SELECT 
    *, 
    CASE WHEN time_taken < 31 THEN '0-30 days' WHEN time_taken < 61 THEN '31-60 days' WHEN time_taken < 91 THEN '61-90 days' WHEN time_taken < 121 THEN '91-120 days' WHEN time_taken < 151 THEN '121-150 days' WHEN time_taken > 150 THEN 'Over 150 days' END AS Category 
  FROM 
    TIME_TO_ANNUAL
) 
SELECT 
  Category, 
  COUNT(CUSTOMER_ID) 
FROM 
  CATEGORISED 
GROUP BY 
  Category 
ORDER BY 
  Category;
-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH Plan_Table AS (
  SELECT 
    ROW_NUMBER() OVER(
      PARTITION BY S.CUSTOMER_ID 
      ORDER BY 
        S.PLAN_ID ASC
    ) AS Plan_Order, 
    CUSTOMER_ID, 
    S.PLAN_ID, 
    START_DATE, 
    PLAN_NAME, 
    PRICE 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  ORDER BY 
    CUSTOMER_ID, 
    START_DATE
), 
basic_monthlys_started_2020 AS (
  SELECT 
    CUSTOMER_ID, 
    START_DATE AS basic_monthly_start_date, 
    p.PLAN_ID, 
    PLAN_NAME AS basic_monthly 
  FROM 
    SUBSCRIPTIONS S 
    JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID 
  WHERE 
    YEAR(START_DATE) = 2020 
    AND PLAN_NAME = 'basic monthly' 
  ORDER BY 
    CUSTOMER_ID, 
    START_DATE
) 
SELECT 
  p.CUSTOMER_ID, 
  BASIC_MONTHLY_START_DATE, 
  PLAN_ORDER, 
  p.PLAN_ID, 
  START_DATE, 
  PLAN_NAME 
FROM 
  basic_monthlys_started_2020 b 
  INNER JOIN PLAN_TABLE p ON p.customer_id = b.customer_id 
WHERE 
  DATEDIFF(
    DAY, basic_monthly_start_date, start_date
  ) < 1 
  AND plan_name = 'pro monthly' 
ORDER BY 
  p.CUSTOMER_ID, 
  START_DATE;
