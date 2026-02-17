CREATE database Zepto_Project;
use Zepto_Project;

select * from orders;
select * from users;
select * from order_items;
select * from user_activity;
select * from support_tickets;

# Create User Metrics
CREATE TABLE user_metrics AS
WITH order_metrics AS (
    SELECT
        o.user_id,
        MAX(o.order_date) AS last_order_date,
        COUNT(o.order_id) AS total_orders,
        COUNT(
            CASE 
                WHEN o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
                THEN o.order_id
            END
        ) AS orders_last_30_days,
        AVG(o.order_value) AS avg_order_value,
        AVG(o.delivery_time_minutes) AS avg_delivery_time,
        AVG(o.order_rating) AS avg_order_rating
    FROM orders o
    WHERE o.delivery_status = 'Delivered'
    GROUP BY o.user_id
),

activity_metrics AS (
    SELECT
        ua.user_id,
        AVG(ua.app_opens) AS avg_app_opens,
        AVG(ua.time_spent_minutes) AS avg_time_spent_minutes,
        AVG(ua.pages_viewed) AS avg_pages_viewed,
        AVG(
            CASE 
                WHEN ua.coupon_applied = 'Yes' THEN 1 
                ELSE 0 
            END
        ) AS coupon_usage_rate
    FROM user_activity ua
    GROUP BY ua.user_id
),

support_metrics AS (
    SELECT
        st.user_id,
        COUNT(st.ticket_id) AS support_ticket_count,
        AVG(st.resolution_time_hours) AS avg_resolution_time_hours
    FROM support_tickets st
    GROUP BY st.user_id
)

SELECT
    u.user_id,

    -- Order metrics
    om.last_order_date,
    DATEDIFF(CURRENT_DATE, om.last_order_date) AS days_since_last_order,
    COALESCE(om.total_orders, 0) AS total_orders,
    COALESCE(om.orders_last_30_days, 0) AS orders_last_30_days,
    ROUND(COALESCE(om.avg_order_value, 0), 2) AS avg_order_value,
    ROUND(COALESCE(om.avg_delivery_time, 0), 2) AS avg_delivery_time,
    ROUND(COALESCE(om.avg_order_rating, 0), 2) AS avg_order_rating,

    -- App engagement
    ROUND(COALESCE(am.avg_app_opens, 0), 2) AS avg_app_opens,
    ROUND(COALESCE(am.avg_time_spent_minutes, 0), 2) AS avg_time_spent_minutes,
    ROUND(COALESCE(am.avg_pages_viewed, 0), 2) AS avg_pages_viewed,
    ROUND(COALESCE(am.coupon_usage_rate, 0), 2) AS coupon_usage_rate,

    -- Support experience
    COALESCE(sm.support_ticket_count, 0) AS support_ticket_count,
    ROUND(COALESCE(sm.avg_resolution_time_hours, 0), 2) AS avg_resolution_time_hours,

    CASE 
        WHEN COALESCE(sm.support_ticket_count, 0) > 0 THEN 1
        ELSE 0
    END AS has_support_issue,

    -- Churn flag
    CASE
        WHEN om.last_order_date < DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
        THEN 1
        ELSE 0
    END AS churn_flag

FROM users u
LEFT JOIN order_metrics om ON u.user_id = om.user_id
LEFT JOIN activity_metrics am ON u.user_id = am.user_id
LEFT JOIN support_metrics sm ON u.user_id = sm.user_id;

SELECT COUNT(*) FROM user_metrics;

SELECT churn_flag, COUNT(*) 
FROM user_metrics 
GROUP BY churn_flag;

SELECT * FROM user_metrics LIMIT 10;

# Churn Rate 
SELECT 
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_percent
FROM user_metrics;

# Hign Risk Users
SELECT *
FROM user_metrics
WHERE days_since_last_order BETWEEN 21 AND 30;

# ADD New Derived Columns
ALTER TABLE user_metrics
ADD COLUMN engagement_score DECIMAL(10,2),
ADD COLUMN order_frequency_per_month DECIMAL(10,2),
ADD COLUMN value_segment VARCHAR(20),
ADD COLUMN churn_risk_segment VARCHAR(20);

# Updating user Metrics
UPDATE user_metrics
SET
#>> 1.️Engagement Score (weighted)
    engagement_score = 
        (0.4 * avg_app_opens) +
        (0.4 * avg_time_spent_minutes) +
        (0.2 * avg_pages_viewed),

#>> 2. Order Frequency Per Month
    order_frequency_per_month = 
        CASE 
            WHEN days_since_last_order IS NULL THEN 0
            WHEN days_since_last_order = 0 THEN total_orders
            ELSE ROUND(total_orders / GREATEST(days_since_last_order / 30, 1), 2)
        END,

#>> 3.️Value Segment
    value_segment =
        CASE
            WHEN avg_order_value >= 600 THEN 'High Value'
            WHEN avg_order_value BETWEEN 300 AND 599 THEN 'Medium Value'
            ELSE 'Low Value'
        END,

#>> 4️.Churn Risk Segment
    churn_risk_segment =
        CASE
            WHEN days_since_last_order > 30 THEN 'High Risk'
            WHEN days_since_last_order BETWEEN 15 AND 30 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END;


SET SQL_SAFE_UPDATES = 1;
SET SQL_SAFE_UPDATES = 0;

SELECT COUNT(*) 
FROM user_metrics
WHERE days_since_last_order IS NULL;

UPDATE user_metrics
SET churn_risk_segment =
CASE
    WHEN days_since_last_order > 30 THEN 'High Risk'
    WHEN days_since_last_order BETWEEN 15 AND 30 THEN 'Medium Risk'
    ELSE 'Low Risk'
END
WHERE days_since_last_order IS NOT NULL;



# Business Queries : 


#>> SECTION 1: REVENUE IMPACT (8 Questions)

# 1.What is the total revenue lost due to churned users?
SELECT SUM(avg_order_value * total_orders) AS revenue_lost
FROM user_metrics
WHERE churn_flag = 1;

# 2.What percentage of total revenue comes from churned users?
SELECT 
    ROUND(
        (SUM(CASE WHEN churn_flag = 1 THEN avg_order_value * total_orders END) 
        / SUM(avg_order_value * total_orders)) * 100, 2
    ) AS percent_revenue_lost
FROM user_metrics;

# 3️.How much revenue is at risk from High-Risk users?
SELECT SUM(avg_order_value * total_orders) AS revenue_at_risk
FROM user_metrics
WHERE churn_risk_segment = 'High Risk';

# 4️.Among churned users, how many belong to the High Value segment?
SELECT COUNT(*) AS high_value_churned
FROM user_metrics
WHERE churn_flag = 1
AND value_segment = 'High Value';

# 5️.What is the average order value of churned vs retained users?
SELECT churn_flag,
       ROUND(AVG(avg_order_value),2) AS avg_order_value
FROM user_metrics
GROUP BY churn_flag;

# 6️.What is the total lifetime revenue generated by churned users?

SELECT SUM(avg_order_value * total_orders) AS lifetime_revenue_churned
FROM user_metrics
WHERE churn_flag = 1;

# 7️.Which city contributes the highest revenue loss due to churn?

SELECT u.city,
       SUM(um.avg_order_value * um.total_orders) AS revenue_lost
FROM user_metrics um
JOIN users u ON um.user_id = u.user_id
WHERE um.churn_flag = 1
GROUP BY u.city
ORDER BY revenue_lost DESC;

# 8️.What is the potential monthly revenue loss if all High-Risk users churn?

SELECT SUM(avg_order_value * orders_last_30_days) AS monthly_revenue_risk
FROM user_metrics
WHERE churn_risk_segment = 'High Risk';

#>> SECTION 2: COHORT ANALYSIS (8 Questions)

# 9️.What is the retention rate of users grouped by signup month?

SELECT DATE_FORMAT(signup_date, '%Y-%m') AS cohort,
       ROUND(100 - (AVG(churn_flag) * 100),2) AS retention_rate
FROM users u
JOIN user_metrics um ON u.user_id = um.user_id
GROUP BY cohort
ORDER BY cohort;

# 10.What percentage of users churn within 30 days of signup?

SELECT ROUND(
    (COUNT(CASE WHEN days_since_last_order <= 30 AND churn_flag = 1 THEN 1 END)
    / COUNT(*)) * 100, 2) AS early_churn_percent
FROM user_metrics;

# 1️1.What is the 60-day retention rate by signup cohort?

SELECT DATE_FORMAT(signup_date, '%Y-%m') AS cohort,
       ROUND(100 - (AVG(CASE WHEN days_since_last_order > 60 THEN 1 ELSE 0 END) * 100),2) AS retention_60_day
FROM users u
JOIN user_metrics um ON u.user_id = um.user_id
GROUP BY cohort;

# 1️2.Which signup cohort has the highest churn rate?

SELECT DATE_FORMAT(signup_date, '%Y-%m') AS cohort,
       ROUND(AVG(churn_flag) * 100,2) AS churn_rate
FROM users u
JOIN user_metrics um ON u.user_id = um.user_id
GROUP BY cohort
ORDER BY churn_rate DESC;

# 1️3.What is the average revenue per cohort (signup month basis)?
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS cohort,
       ROUND(AVG(avg_order_value * total_orders),2) AS avg_revenue
FROM users u
JOIN user_metrics um ON u.user_id = um.user_id
GROUP BY cohort;

# 1️4.How does order frequency differ across cohorts?
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS cohort,
       ROUND(AVG(order_frequency_per_month),2) AS avg_order_freq
FROM users u
JOIN user_metrics um ON u.user_id = um.user_id
GROUP BY cohort;

# 1️5.What is the average engagement score by cohort?
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS cohort,
       ROUND(AVG(engagement_score),2) AS avg_engagement
FROM users u
JOIN user_metrics um ON u.user_id = um.user_id
GROUP BY cohort;

# 1️6.Are newer cohorts churning faster than older cohorts?

WITH max_signup AS (
    SELECT MAX(signup_date) AS max_signup_date
    FROM users
)

SELECT
    CASE
        WHEN u.signup_date >= DATE_SUB(ms.max_signup_date, INTERVAL 90 DAY)
        THEN 'New Users'
        ELSE 'Old Users'
    END AS user_group,
    ROUND(AVG(um.churn_flag) * 100, 2) AS churn_rate
FROM users u
JOIN user_metrics um ON u.user_id = um.user_id
CROSS JOIN max_signup ms
GROUP BY user_group;

# >> SECTION 3: RISK SEGMENTATION (7 Questions)

# 1️7.How many users fall into each churn_risk_segment?

SELECT churn_risk_segment, COUNT(*) AS total_users
FROM user_metrics
GROUP BY churn_risk_segment;

# 1️8.What is the revenue distribution across risk segments?

SELECT churn_risk_segment,
       SUM(avg_order_value * total_orders) AS revenue
FROM user_metrics
GROUP BY churn_risk_segment;



# 1️9.What percentage of High-Risk users are High-Value users?

SELECT 
ROUND(
(COUNT(CASE WHEN churn_risk_segment='High Risk' AND value_segment='High Value' THEN 1 END)
/
COUNT(CASE WHEN churn_risk_segment='High Risk' THEN 1 END)) *100,2
) AS percent_high_value_high_risk
FROM user_metrics;


# 2️0.What is the average engagement score by churn risk segment?

SELECT churn_risk_segment,
       ROUND(AVG(engagement_score),2) AS avg_engagement
FROM user_metrics
GROUP BY churn_risk_segment;

# 2️1.How does order frequency differ between Low-Risk and High-Risk users?

SELECT churn_risk_segment,
       ROUND(AVG(order_frequency_per_month),2) AS avg_order_freq
FROM user_metrics
GROUP BY churn_risk_segment;

# 2️2. What is the support ticket count distribution by risk segment?

SELECT churn_risk_segment,
       ROUND(AVG(support_ticket_count),2) AS avg_tickets
FROM user_metrics
GROUP BY churn_risk_segment;


# 2️3.How many Medium-Risk users moved to High-Risk (simulate trend using recency)?

SELECT COUNT(*) AS medium_risk_near_high
FROM user_metrics
WHERE churn_risk_segment='Medium Risk'
AND days_since_last_order >= 25;

#>>  SECTION 4: EXPERIENCE CORRELATION (7 Questions)

# 2️4.What is the churn rate among users who raised at least one support ticket?

SELECT 
CASE WHEN support_ticket_count > 0 THEN 'Had Ticket' ELSE 'No Ticket' END AS ticket_status,
ROUND(AVG(churn_flag)*100,2) AS churn_rate
FROM user_metrics
GROUP BY ticket_status;


# 2️5.What is the churn rate for users with more than 2 tickets?

SELECT 
ROUND(AVG(churn_flag)*100,2) AS churn_rate_high_ticket
FROM user_metrics
WHERE support_ticket_count > 2;


# 2️6.Does higher avg_delivery_time correlate with higher churn?

SELECT churn_flag,
       ROUND(AVG(avg_delivery_time),2) AS avg_delivery_time
FROM user_metrics
GROUP BY churn_flag;

# 2️7.What is the average resolution time for churned vs retained users?

SELECT churn_flag,
       ROUND(AVG(avg_resolution_time_hours),2) AS avg_resolution_time
FROM user_metrics
GROUP BY churn_flag;

# 2️8.What is the churn rate among users who experienced delayed deliveries?

SELECT 
ROUND(AVG(CASE WHEN avg_delivery_time > 25 THEN churn_flag END)*100,2) 
AS churn_rate_delayed
FROM user_metrics;

# 2️9.How does order_rating differ between churned and retained users?

SELECT churn_flag,
       ROUND(AVG(avg_order_rating),2) AS avg_rating
FROM user_metrics
GROUP BY churn_flag;

# 3️0.Among High-Risk users, what percentage have experience-related issues?

SELECT 
ROUND(
(COUNT(CASE WHEN churn_risk_segment='High Risk' AND has_support_issue=1 THEN 1 END)
/
COUNT(CASE WHEN churn_risk_segment='High Risk' THEN 1 END)) *100,2
) AS percent_high_risk_with_issues
FROM user_metrics;








