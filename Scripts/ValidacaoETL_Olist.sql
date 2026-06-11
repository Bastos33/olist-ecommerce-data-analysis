-- ==========================================================
-- VALIDAÇÃO COMPLETA | FACT_SALES / FACT_PAYMENT vs STG
-- Totais + joins + duplicações + chaves órfãs
-- ========================================================== */

------------------------------------------------------------
-- CONTAGEM DE LINHAS
------------------------------------------------------------
SELECT 'STG_ORDER_ITEMS' AS teste, COUNT(*) AS qtd
FROM dbo.olist_order_items_stg--11265

UNION ALL
SELECT 'FACT_SALES', COUNT(*)--11265
FROM fact_sales

UNION ALL
SELECT 'STG_PAYMENTS', COUNT(*)--99440
FROM dbo.olist_payments_stg

UNION ALL
SELECT 'FACT_PAYMENT', COUNT(*)--99440
FROM fact_payment;


------------------------------------------------------------
--  TOTAL FINANCEIRO SALES
------------------------------------------------------------
SELECT
'VALOR_ITENS_STG' AS teste,
SUM(price) AS total
FROM dbo.olist_order_items_stg

UNION ALL

SELECT
'VALOR_ITENS_FACT',
SUM(price)
FROM fact_sales

UNION ALL

SELECT
'FRETE_STG',
SUM(freight)
FROM dbo.olist_order_items_stg

UNION ALL

SELECT
'FRETE_FACT',
SUM(freight)
FROM fact_sales;
--Valor_itens_STG:13591643.70
--Valor_itens_FACT:13591643.70
--Frete_STG:22519009.54
--Frete_FACT:22519009.54
------------------------------------------------------------
--  TOTAL PAGAMENTOS
------------------------------------------------------------
SELECT
'PAYMENT_STG' AS teste,
SUM(payment_value) AS total
FROM dbo.olist_payments_stg

UNION ALL

SELECT
'PAYMENT_FACT',
SUM(payment_value)
FROM fact_payment;
--PAYMENT_STG:16008872.12
--PAYMENT_FACT:16008872.12
------------------------------------------------------------
-- PK DUPLICADA FACT_SALES
------------------------------------------------------------
SELECT
order_id,
order_item_id,
COUNT(*) AS repeticoes
FROM fact_sales
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
---0
------------------------------------------------------------
-- CHAVES NULAS FACT_SALES
------------------------------------------------------------
SELECT
SUM(CASE WHEN sk_customer IS NULL THEN 1 ELSE 0 END) AS customer_null,
SUM(CASE WHEN sk_product  IS NULL THEN 1 ELSE 0 END) AS product_null,
SUM(CASE WHEN sk_seller   IS NULL THEN 1 ELSE 0 END) AS seller_null,
SUM(CASE WHEN date_key    IS NULL THEN 1 ELSE 0 END) AS date_null
FROM fact_sales;

--0