CREATE OR ALTER VIEW vw_kpi_entregas
AS

SELECT
    COUNT(*) AS total_pedidos,

    SUM(
        CASE
            WHEN delivered_customer_date <= estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS pedidos_no_prazo,

    SUM(
        CASE
            WHEN delivered_customer_date > estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS pedidos_atrasados,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN delivered_customer_date <= estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS pct_entregas_no_prazo,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN delivered_customer_date > estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS pct_entregas_atrasadas,

    AVG(
        CAST(review_score AS DECIMAL(10,2))
    ) AS nota_media_review,

    AVG(
        CASE
            WHEN delivered_customer_date > estimated_delivery_date
            THEN DATEDIFF(
                    DAY,
                    estimated_delivery_date,
                    delivered_customer_date
                 )
        END
    ) AS atraso_medio_dias

FROM dbo.olist_orders_stg o

LEFT JOIN dbo.olist_order_reviews_dataset r
       ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.delivered_customer_date >= '2017-11-01'
  AND o.delivered_customer_date < '2018-09-01'
  AND o.delivered_customer_date IS NOT NULL
  AND o.estimated_delivery_date IS NOT NULL;
GO