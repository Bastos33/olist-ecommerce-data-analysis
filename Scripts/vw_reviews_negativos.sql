CREATE OR ALTER VIEW vw_reviews_negativos
AS

SELECT
      r.review_id
    , r.order_id
    , r.review_score
    , r.review_comment_title
    , r.review_comment_message
    , o.delivered_customer_date
    , o.estimated_delivery_date

    , CASE
          WHEN o.delivered_customer_date <= o.estimated_delivery_date
          THEN 'NO PRAZO'
          ELSE 'ATRASADO'
      END AS status_entrega

    , CAST(
          100.0 /
          (SELECT COUNT(*)
           FROM dbo.olist_order_reviews_dataset)
          AS DECIMAL(10,4)
      ) AS pct_do_total_reviews

FROM dbo.olist_order_reviews_dataset r

INNER JOIN dbo.olist_orders_stg o
        ON r.order_id = o.order_id

WHERE r.review_score <= 3;
GO