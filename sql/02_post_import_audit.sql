-- i run read-only post-import audit checks after csv import
-- i compare observed values with expected values from the pandas data audit

WITH checks AS (
    -- i check table row counts
    SELECT 'ROWS: customers' AS check_name, COUNT(*)::bigint AS observed, 99441::bigint AS expected FROM public.customers
    UNION ALL SELECT 'ROWS: geolocation', COUNT(*)::bigint, 1000163::bigint FROM public.geolocation
    UNION ALL SELECT 'ROWS: order_items', COUNT(*)::bigint, 112650::bigint FROM public.order_items
    UNION ALL SELECT 'ROWS: order_payments', COUNT(*)::bigint, 103886::bigint FROM public.order_payments
    UNION ALL SELECT 'ROWS: order_reviews', COUNT(*)::bigint, 99224::bigint FROM public.order_reviews
    UNION ALL SELECT 'ROWS: orders', COUNT(*)::bigint, 99441::bigint FROM public.orders
    UNION ALL SELECT 'ROWS: products', COUNT(*)::bigint, 32951::bigint FROM public.products
    UNION ALL SELECT 'ROWS: sellers', COUNT(*)::bigint, 3095::bigint FROM public.sellers
    UNION ALL SELECT 'ROWS: category_translation', COUNT(*)::bigint, 71::bigint FROM public.category_translation

    -- i verify uniqueness of candidate primary keys
    UNION ALL SELECT 'DUPLICATE PK: customers.customer_id', COUNT(*)::bigint - COUNT(DISTINCT customer_id)::bigint, 0::bigint FROM public.customers
    UNION ALL SELECT 'DUPLICATE PK: orders.order_id', COUNT(*)::bigint - COUNT(DISTINCT order_id)::bigint, 0::bigint FROM public.orders
    UNION ALL SELECT 'DUPLICATE PK: products.product_id', COUNT(*)::bigint - COUNT(DISTINCT product_id)::bigint, 0::bigint FROM public.products
    UNION ALL SELECT 'DUPLICATE PK: sellers.seller_id', COUNT(*)::bigint - COUNT(DISTINCT seller_id)::bigint, 0::bigint FROM public.sellers
    UNION ALL SELECT 'DUPLICATE PK: category_translation.product_category_name', COUNT(*)::bigint - COUNT(DISTINCT product_category_name)::bigint, 0::bigint FROM public.category_translation
    UNION ALL SELECT 'DUPLICATE COMPOSITE PK: order_items', COUNT(*)::bigint - COUNT(DISTINCT (order_id, order_item_id))::bigint, 0::bigint FROM public.order_items
    UNION ALL SELECT 'DUPLICATE COMPOSITE PK: order_payments', COUNT(*)::bigint - COUNT(DISTINCT (order_id, payment_sequential))::bigint, 0::bigint FROM public.order_payments
    UNION ALL SELECT 'DUPLICATE COMPOSITE PK: order_reviews', COUNT(*)::bigint - COUNT(DISTINCT (review_id, order_id))::bigint, 0::bigint FROM public.order_reviews

    -- i check referential integrity for orphan foreign keys
    UNION ALL SELECT 'ORPHAN FK: orders -> customers', COUNT(*)::bigint, 0::bigint FROM public.orders o LEFT JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL
    UNION ALL SELECT 'ORPHAN FK: order_items -> orders', COUNT(*)::bigint, 0::bigint FROM public.order_items oi LEFT JOIN public.orders o ON oi.order_id = o.order_id WHERE o.order_id IS NULL
    UNION ALL SELECT 'ORPHAN FK: order_items -> products', COUNT(*)::bigint, 0::bigint FROM public.order_items oi LEFT JOIN public.products p ON oi.product_id = p.product_id WHERE p.product_id IS NULL
    UNION ALL SELECT 'ORPHAN FK: order_items -> sellers', COUNT(*)::bigint, 0::bigint FROM public.order_items oi LEFT JOIN public.sellers s ON oi.seller_id = s.seller_id WHERE s.seller_id IS NULL
    UNION ALL SELECT 'ORPHAN FK: order_payments -> orders', COUNT(*)::bigint, 0::bigint FROM public.order_payments op LEFT JOIN public.orders o ON op.order_id = o.order_id WHERE o.order_id IS NULL
    UNION ALL SELECT 'ORPHAN FK: order_reviews -> orders', COUNT(*)::bigint, 0::bigint FROM public.order_reviews r LEFT JOIN public.orders o ON r.order_id = o.order_id WHERE o.order_id IS NULL

    -- i verify that csv header rows were not imported as data
    UNION ALL SELECT 'HEADER ROW: customers', COUNT(*)::bigint, 0::bigint FROM public.customers WHERE customer_id = 'customer_id'
    UNION ALL SELECT 'HEADER ROW: geolocation', COUNT(*)::bigint, 0::bigint FROM public.geolocation WHERE geolocation_zip_code_prefix = 'geolocation_zip_code_prefix'
    UNION ALL SELECT 'HEADER ROW: order_items', COUNT(*)::bigint, 0::bigint FROM public.order_items WHERE order_id = 'order_id'
    UNION ALL SELECT 'HEADER ROW: order_payments', COUNT(*)::bigint, 0::bigint FROM public.order_payments WHERE order_id = 'order_id'
    UNION ALL SELECT 'HEADER ROW: order_reviews', COUNT(*)::bigint, 0::bigint FROM public.order_reviews WHERE review_id = 'review_id'
    UNION ALL SELECT 'HEADER ROW: orders', COUNT(*)::bigint, 0::bigint FROM public.orders WHERE order_id = 'order_id'
    UNION ALL SELECT 'HEADER ROW: products', COUNT(*)::bigint, 0::bigint FROM public.products WHERE product_id = 'product_id'
    UNION ALL SELECT 'HEADER ROW: sellers', COUNT(*)::bigint, 0::bigint FROM public.sellers WHERE seller_id = 'seller_id'
    UNION ALL SELECT 'HEADER ROW: category_translation', COUNT(*)::bigint, 0::bigint FROM public.category_translation WHERE product_category_name = 'product_category_name'

    -- i check expected null counts identified during data audit
    UNION ALL SELECT 'NULL: orders.order_approved_at', COUNT(*)::bigint, 160::bigint FROM public.orders WHERE order_approved_at IS NULL
    UNION ALL SELECT 'NULL: orders.order_delivered_carrier_date', COUNT(*)::bigint, 1783::bigint FROM public.orders WHERE order_delivered_carrier_date IS NULL
    UNION ALL SELECT 'NULL: orders.order_delivered_customer_date', COUNT(*)::bigint, 2965::bigint FROM public.orders WHERE order_delivered_customer_date IS NULL
    UNION ALL SELECT 'NULL: products.product_category_name', COUNT(*)::bigint, 610::bigint FROM public.products WHERE product_category_name IS NULL
    UNION ALL SELECT 'NULL: products.product_weight_g', COUNT(*)::bigint, 2::bigint FROM public.products WHERE product_weight_g IS NULL
    UNION ALL SELECT 'NULL: order_reviews.review_comment_title', COUNT(*)::bigint, 87656::bigint FROM public.order_reviews WHERE review_comment_title IS NULL
    UNION ALL SELECT 'NULL: order_reviews.review_comment_message', COUNT(*)::bigint, 58247::bigint FROM public.order_reviews WHERE review_comment_message IS NULL

    -- i verify geolocation has repeated zip prefixes and full rows by design
    UNION ALL SELECT 'UNIQUE ZIP PREFIX: geolocation', COUNT(DISTINCT geolocation_zip_code_prefix)::bigint, 19015::bigint FROM public.geolocation
    UNION ALL SELECT 'REPEATED FULL ROWS: geolocation', COUNT(*)::bigint - COUNT(DISTINCT (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state))::bigint, 261831::bigint FROM public.geolocation

    -- i check product category translation coverage
    UNION ALL SELECT 'PRODUCTS WITHOUT ENGLISH TRANSLATION', COUNT(*)::bigint, 623::bigint FROM public.products p LEFT JOIN public.category_translation ct ON p.product_category_name = ct.product_category_name WHERE ct.product_category_name_english IS NULL
    UNION ALL SELECT 'NON-NULL CATEGORY WITHOUT MAPPING', COUNT(*)::bigint, 13::bigint FROM public.products p LEFT JOIN public.category_translation ct ON p.product_category_name = ct.product_category_name WHERE p.product_category_name IS NOT NULL AND ct.product_category_name IS NULL)

SELECT check_name, observed, expected, CASE WHEN observed = expected THEN 'OK' ELSE 'CHECK' END AS status FROM checks ORDER BY CASE WHEN observed = expected THEN 1 ELSE 0 END, check_name;