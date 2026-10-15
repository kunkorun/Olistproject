-- i run business analysis queries for the olist e-commerce dataset
-- i run one section at a time in pgadmin query tool
-- the queries below are the final versions and earlier exploratory versions have been removed

-- i compare monthly item value across all order statuses with delivered orders only
-- i use this to export monthly_olist_sales.csv for python visualization
-- i note that item_value_all_statuses is gross item value and can include canceled orders
WITH monthly_item_values AS (
    SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month, SUM(oi.price) AS item_value_all_statuses, SUM(oi.price) FILTER (WHERE o.order_status = 'delivered') AS item_value_delivered
    FROM public.orders AS o JOIN public.order_items AS oi ON o.order_id = oi.order_id
    GROUP BY 1),
monthly_order_counts AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month, COUNT(*) AS orders_all_statuses, COUNT(*) FILTER (WHERE order_status = 'delivered') AS delivered_orders
    FROM public.orders
    GROUP BY 1),
period AS (
    SELECT DATE_TRUNC('month', MIN(order_purchase_timestamp))::date AS first_month, DATE_TRUNC('month', MAX(order_purchase_timestamp))::date AS last_month
    FROM public.orders)
SELECT gs.month::date AS month, COALESCE(v.item_value_all_statuses, 0) AS item_value_all_statuses, COALESCE(v.item_value_delivered, 0) AS item_value_delivered, COALESCE(c.orders_all_statuses, 0) AS orders_all_statuses, COALESCE(c.delivered_orders, 0) AS delivered_orders
FROM period AS p
CROSS JOIN LATERAL GENERATE_SERIES(p.first_month::timestamp, p.last_month::timestamp, INTERVAL '1 month') AS gs(month)
LEFT JOIN monthly_item_values AS v ON v.month = gs.month::date
LEFT JOIN monthly_order_counts AS c ON c.month = gs.month::date
ORDER BY gs.month;

-- i explain the october to november 2017 item-value spike
-- i compare monthly item value, delivered order count and average item value per delivered order with the previous month
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month, SUM(oi.price) AS delivered_item_sales, COUNT(DISTINCT o.order_id) AS delivered_orders
    FROM public.orders AS o JOIN public.order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1),
averages AS (
    SELECT month, delivered_item_sales, delivered_orders, delivered_item_sales / NULLIF(delivered_orders, 0) AS avg_item_sales_per_order
    FROM monthly),
comparison AS (
    SELECT *, LAG(delivered_item_sales) OVER (ORDER BY month) AS prev_sales, LAG(delivered_orders) OVER (ORDER BY month) AS prev_orders, LAG(avg_item_sales_per_order) OVER (ORDER BY month) AS prev_avg_sales
    FROM averages)
SELECT month, ROUND(delivered_item_sales::numeric, 2) AS delivered_item_sales, delivered_orders, ROUND(avg_item_sales_per_order::numeric, 2) AS avg_item_sales_per_order, ROUND((100.0 * (delivered_item_sales / NULLIF(prev_sales, 0) - 1))::numeric, 2) AS sales_change_pct, ROUND(100.0 * (delivered_orders::numeric / NULLIF(prev_orders, 0) - 1), 2) AS orders_change_pct, ROUND((100.0 * (avg_item_sales_per_order / NULLIF(prev_avg_sales, 0) - 1))::numeric, 2) AS avg_order_value_change_pct
FROM comparison
WHERE month IN (DATE '2017-10-01', DATE '2017-11-01')
ORDER BY month;

-- i compare year-over-year for january-august 2017 vs 2018
-- i use only the january-august window because the last months of 2018 have very few orders
WITH monthly AS (
    SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp)::integer AS month_number, SUM(oi.price) FILTER (WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017) AS sales_2017, SUM(oi.price) FILTER (WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018) AS sales_2018, COUNT(DISTINCT o.order_id) FILTER (WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017) AS orders_2017, COUNT(DISTINCT o.order_id) FILTER (WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018) AS orders_2018
    FROM public.orders AS o JOIN public.order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered' AND o.order_purchase_timestamp >= DATE '2017-01-01' AND o.order_purchase_timestamp < DATE '2018-09-01'
    GROUP BY 1)
SELECT month_number, ROUND(sales_2017::numeric, 2) AS sales_2017, ROUND(sales_2018::numeric, 2) AS sales_2018, ROUND((100.0 * (sales_2018 / NULLIF(sales_2017, 0) - 1))::numeric, 2) AS sales_change_pct, orders_2017, orders_2018, ROUND(100.0 * (orders_2018::numeric / NULLIF(orders_2017, 0) - 1), 2) AS orders_change_pct
FROM monthly
WHERE month_number BETWEEN 1 AND 8
ORDER BY month_number;

-- i compare each month share of january-august item value between 2017 and 2018
-- i compare within-period mix instead of absolute scale and i note this does not by itself prove seasonality
WITH monthly_sales AS (
    SELECT EXTRACT(YEAR FROM o.order_purchase_timestamp)::integer AS order_year, EXTRACT(MONTH FROM o.order_purchase_timestamp)::integer AS month_number, SUM(oi.price) AS delivered_item_sales, COUNT(DISTINCT o.order_id) AS delivered_orders
    FROM public.orders AS o JOIN public.order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered' AND o.order_purchase_timestamp >= DATE '2017-01-01' AND o.order_purchase_timestamp < DATE '2018-09-01'
    GROUP BY 1, 2),
monthly_shares AS (
    SELECT *, 100.0 * delivered_item_sales / SUM(delivered_item_sales) OVER (PARTITION BY order_year) AS share_of_period_sales, 100.0 * delivered_orders / SUM(delivered_orders) OVER (PARTITION BY order_year) AS share_of_period_orders
    FROM monthly_sales
    WHERE month_number BETWEEN 1 AND 8)
SELECT month_number, ROUND(MAX(delivered_item_sales) FILTER (WHERE order_year = 2017)::numeric, 2) AS sales_2017, ROUND(MAX(delivered_item_sales) FILTER (WHERE order_year = 2018)::numeric, 2) AS sales_2018, ROUND(MAX(share_of_period_sales) FILTER (WHERE order_year = 2017)::numeric, 2) AS sales_share_2017_pct, ROUND(MAX(share_of_period_sales) FILTER (WHERE order_year = 2018)::numeric, 2) AS sales_share_2018_pct, ROUND((MAX(share_of_period_sales) FILTER (WHERE order_year = 2018) - MAX(share_of_period_sales) FILTER (WHERE order_year = 2017))::numeric, 2) AS share_change_pp
FROM monthly_shares
GROUP BY month_number
ORDER BY month_number;

-- i calculate the overall late delivery rate based on calendar dates
-- i include only delivered orders with both dates and i ignore time-of-day
SELECT COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL) AS eligible_orders, COUNT(*) FILTER (WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date) AS late_orders, COUNT(*) FILTER (WHERE order_delivered_customer_date::date <= order_estimated_delivery_date::date) AS on_time_or_early_orders, ROUND(100.0 * COUNT(*) FILTER (WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date) / NULLIF(COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL), 0), 2) AS late_rate_pct
FROM public.orders
WHERE order_status = 'delivered';

-- i calculate the monthly late delivery rate using the calendar-date definition
-- i note that the month refers to the order purchase month and the period ends in august 2018 because september and october 2018 are incomplete
SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month, COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL) AS eligible_orders, COUNT(*) FILTER (WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date) AS late_orders, ROUND(100.0 * COUNT(*) FILTER (WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date) / NULLIF(COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL), 0), 2) AS late_rate_pct
FROM public.orders
WHERE order_status = 'delivered' AND order_purchase_timestamp >= DATE '2017-01-01' AND order_purchase_timestamp < DATE '2018-09-01'
GROUP BY 1
ORDER BY 1;

-- i calculate the average and median lateness duration by order purchase month
-- i measure delay in calendar days only for late delivered orders with both dates available
WITH delivery_delays AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month, order_delivered_customer_date::date - order_estimated_delivery_date::date AS delay_days
    FROM public.orders
    WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL AND order_purchase_timestamp >= DATE '2017-01-01' AND order_purchase_timestamp < DATE '2018-09-01')
SELECT month, COUNT(*) FILTER (WHERE delay_days > 0) AS late_orders, ROUND(AVG(delay_days) FILTER (WHERE delay_days > 0), 2) AS avg_days_late, ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delay_days) FILTER (WHERE delay_days > 0))::numeric, 2) AS median_days_late
FROM delivery_delays
GROUP BY month
ORDER BY month;

-- i analyze the first-order rating and subsequent purchases using customer_unique_id as buyer identity
-- i require that a repeat purchase is placed after the latest review date of the first chronological order
-- i note this identifies association rather than causation
WITH reviews_by_order AS (
    SELECT order_id, AVG(review_score) AS avg_review_score, MAX(review_creation_date) AS latest_review_date
    FROM public.order_reviews
    GROUP BY order_id),
ranked_orders AS (
    SELECT c.customer_unique_id, o.order_id, o.order_purchase_timestamp, r.avg_review_score, r.latest_review_date, ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp, o.order_id) AS order_number
    FROM public.orders AS o JOIN public.customers AS c ON o.customer_id = c.customer_id
    LEFT JOIN reviews_by_order AS r ON o.order_id = r.order_id),
first_orders_with_review AS (
    SELECT * FROM ranked_orders
    WHERE order_number = 1 AND avg_review_score IS NOT NULL AND latest_review_date IS NOT NULL),
buyer_outcomes AS (
    SELECT f.customer_unique_id, f.avg_review_score, BOOL_OR(o2.order_id IS NOT NULL) AS repurchased_after_review
    FROM first_orders_with_review AS f
    LEFT JOIN public.customers AS c2 ON c2.customer_unique_id = f.customer_unique_id
    LEFT JOIN public.orders AS o2 ON o2.customer_id = c2.customer_id AND o2.order_id <> f.order_id AND o2.order_purchase_timestamp > f.latest_review_date
    GROUP BY f.customer_unique_id, f.avg_review_score),
buyer_groups AS (
    SELECT CASE WHEN avg_review_score < 3 THEN 'Low (< 3)' WHEN avg_review_score < 4 THEN 'Medium (3 to < 4)' ELSE 'High (4 to 5)' END AS rating_group, CASE WHEN avg_review_score < 3 THEN 1 WHEN avg_review_score < 4 THEN 2 ELSE 3 END AS sort_order, repurchased_after_review
    FROM buyer_outcomes)
SELECT rating_group, COUNT(*) AS buyers_with_first_review, COUNT(*) FILTER (WHERE repurchased_after_review) AS buyers_who_repurchased, ROUND(100.0 * COUNT(*) FILTER (WHERE repurchased_after_review) / NULLIF(COUNT(*), 0), 2) AS repurchase_rate_pct
FROM buyer_groups
GROUP BY rating_group, sort_order
ORDER BY sort_order;