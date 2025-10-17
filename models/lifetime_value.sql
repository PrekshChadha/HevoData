WITH customer_orders AS (
    SELECT
        cx.id AS customer_id,
        cx.first_name,
        cx.last_name,
        MIN(ord.order_date) AS first_order,
        MAX(ord.order_date) AS most_recent_order,
        COUNT(ord.id) AS number_of_orders
    FROM {{ source('PUBLIC', 'raw_customers') }} cx
    LEFT JOIN {{ source('PUBLIC', 'raw_orders') }} ord
    ON cx.id = ord.user_id
    GROUP BY cx.id, cx.first_name, cx.last_name
),
customer_lifetime_value AS (
    SELECT
        ord.user_id AS customer_id,
        SUM(pyt.amount) AS customer_lifetime_value
    FROM {{ source('PUBLIC', 'raw_orders') }} ord
    LEFT JOIN {{ source('PUBLIC', 'raw_payments') }} pyt
    ON ord.id = pyt.order_id
    GROUP BY ord.user_id
)
SELECT
    cxord.customer_id,
    cxord.first_name,
    cxord.last_name,
    cxord.first_order,
    cxord.most_recent_order,
    cxord.number_of_orders,
    cxlv.customer_lifetime_value
FROM customer_orders cxord
LEFT JOIN customer_lifetime_value cxlv
ON cxord.customer_id = cxlv.customer_id
