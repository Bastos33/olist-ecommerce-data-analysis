-- ======================================
-- STAGING (PADRONIZADO)
-- ======================================

-- CUSTOMERS
DROP TABLE IF EXISTS dbo.olist_customers_stg;
GO
SELECT 
    TRY_CAST(customer_id AS VARCHAR(32)) AS customer_id,
    TRY_CAST(customer_unique_id AS VARCHAR(32)) AS customer_unique_id,
    TRY_CAST(customer_zip_code_prefix AS INT) AS zip_code_prefix,
    UPPER(LTRIM(RTRIM(customer_city))) AS city,
    UPPER(LTRIM(RTRIM(customer_state))) AS state
INTO dbo.olist_customers_stg
FROM Olist_Data.dbo.olist_customers_dataset;
GO

-- PRODUCTS
DROP TABLE IF EXISTS dbo.olist_products_stg;
GO
SELECT 
    product_id,
    product_category_name,
    TRY_CAST(product_weight_g AS INT) AS weight,
    TRY_CAST(product_length_cm AS DECIMAL(10,2)) AS length,
    TRY_CAST(product_height_cm AS DECIMAL(10,2)) AS height,
    TRY_CAST(product_width_cm AS DECIMAL(10,2)) AS width
INTO dbo.olist_products_stg
FROM Olist_Data.dbo.olist_products_dataset;
GO

-- ORDERS
DROP TABLE IF EXISTS dbo.olist_orders_stg;
GO
SELECT 
    order_id,
    customer_id,
    order_status,
    TRY_CAST(order_purchase_timestamp AS DATETIME2) AS purchase_date,
    TRY_CAST(order_delivered_customer_date AS DATETIME2) AS delivered_customer_date,
    TRY_CAST(order_estimated_delivery_date AS DATETIME2) AS estimated_delivery_date
INTO dbo.olist_orders_stg
FROM Olist_Data.dbo.olist_orders_dataset;
GO

-- ORDER ITEMS
DROP TABLE IF EXISTS dbo.olist_order_items_stg;
GO
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    TRY_CAST(price AS DECIMAL(10,2)) AS price,
    TRY_CAST(freight_value AS DECIMAL(10,2)) AS freight
INTO dbo.olist_order_items_stg
FROM Olist_Data.dbo.olist_order_items_dataset;
GO

-- SELLERS
DROP TABLE IF EXISTS dbo.olist_sellers_stg;
GO
SELECT 
    seller_id,
    TRY_CAST(seller_zip_code_prefix AS INT) AS zip_code_prefix,
    UPPER(LTRIM(RTRIM(seller_city))) AS city,
    UPPER(LTRIM(RTRIM(seller_state))) AS state
INTO dbo.olist_sellers_stg
FROM Olist_Data.dbo.olist_sellers_dataset;
GO

-- PAYMENTS
DROP TABLE IF EXISTS dbo.olist_payments_stg;
GO
SELECT 
    order_id,
    SUM(ISNULL(TRY_CAST(payment_value AS DECIMAL(10,2)), 0)) AS payment_value
INTO dbo.olist_payments_stg
FROM Olist_Data.dbo.olist_order_payments_dataset
GROUP BY order_id;
GO

-- GEOLOCATION + CEPs sellers
DROP TABLE IF EXISTS dbo.olist_geolocation_stg;
GO
SELECT 
    TRY_CAST(geolocation_zip_code_prefix AS INT) AS zip_code_prefix,
    TRY_CAST(geolocation_lat AS DECIMAL(10,6)) AS latitude,
    TRY_CAST(geolocation_lng AS DECIMAL(10,6)) AS longitude,
    UPPER(LTRIM(RTRIM(geolocation_city))) AS city,
    UPPER(LTRIM(RTRIM(geolocation_state))) AS state
INTO dbo.olist_geolocation_stg
FROM Olist_Data.dbo.olist_geolocation_dataset

UNION ALL

SELECT 
    TRY_CAST(s.seller_zip_code_prefix AS INT) AS zip_code_prefix,
    NULL AS latitude,
    NULL AS longitude,
    UPPER(LTRIM(RTRIM(s.seller_city))) AS city,
    UPPER(LTRIM(RTRIM(s.seller_state))) AS state
FROM Olist_Data.dbo.olist_sellers_dataset s
WHERE TRY_CAST(s.seller_zip_code_prefix AS INT) IN (2285, 7412, 37708, 71551, 72580, 82040, 91901)
  AND NOT EXISTS (
        SELECT 1
        FROM Olist_Data.dbo.olist_geolocation_dataset g
        WHERE TRY_CAST(g.geolocation_zip_code_prefix AS INT) = TRY_CAST(s.seller_zip_code_prefix AS INT)
  );
GO

/* =====================================================
   DROP DIMENSÕES E FATOS (ordem respeita FK)
   ===================================================== */
DROP TABLE IF EXISTS fact_payment;
GO
DROP TABLE IF EXISTS fact_sales;
GO
DROP TABLE IF EXISTS dim_date;
GO
DROP TABLE IF EXISTS dim_seller;
GO
DROP TABLE IF EXISTS dim_product;
GO
DROP TABLE IF EXISTS dim_customer;
GO
DROP TABLE IF EXISTS dim_geolocation;
GO

/* ======================================
   GEOLOCATION
   ====================================== */
CREATE TABLE dim_geolocation (
    sk_geo          INT IDENTITY(1,1) PRIMARY KEY,
    zip_code_prefix INT NOT NULL UNIQUE,
    city            VARCHAR(100),
    state           CHAR(2),
    latitude        DECIMAL(10,6),
    longitude       DECIMAL(10,6)
);
GO

-- CTE sem ponto-e-vírgula após GO
WITH geo_base AS (
    SELECT DISTINCT zip_code_prefix
    FROM dbo.olist_geolocation_stg
),
geo_avg AS (
    SELECT
        zip_code_prefix,
        AVG(latitude)  AS latitude,
        AVG(longitude) AS longitude
    FROM dbo.olist_geolocation_stg
    GROUP BY zip_code_prefix
),
geo_count AS (
    SELECT
        zip_code_prefix,
        city,
        state,
        COUNT(*) AS freq
    FROM dbo.olist_geolocation_stg
    GROUP BY zip_code_prefix, city, state
),
geo_ranked AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY zip_code_prefix
               ORDER BY freq DESC, city, state
           ) AS rn
    FROM geo_count
)
INSERT INTO dim_geolocation (zip_code_prefix, latitude, longitude, city, state)
SELECT
    b.zip_code_prefix,
    a.latitude,
    a.longitude,
    r.city,
    r.state
FROM geo_base b
LEFT JOIN geo_avg    a ON b.zip_code_prefix = a.zip_code_prefix
LEFT JOIN geo_ranked r ON b.zip_code_prefix = r.zip_code_prefix AND r.rn = 1;
GO

/* ======================================
   CUSTOMER
   ====================================== */
CREATE TABLE dim_customer (
    sk_customer     INT IDENTITY(1,1) PRIMARY KEY,
    customer_id     VARCHAR(50) NOT NULL UNIQUE,
    zip_code_prefix INT,
    sk_geo          INT NULL
);
GO

INSERT INTO dim_customer (customer_id, zip_code_prefix, sk_geo)
SELECT c.customer_id, c.zip_code_prefix, g.sk_geo
FROM (
    SELECT customer_id, zip_code_prefix,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS rn
    FROM dbo.olist_customers_stg
) c
LEFT JOIN dim_geolocation g ON c.zip_code_prefix = g.zip_code_prefix
WHERE c.rn = 1;
GO

/* ======================================
   PRODUCT
   ====================================== */
CREATE TABLE dim_product (
    sk_product            INT IDENTITY(1,1) PRIMARY KEY,
    product_id            VARCHAR(50) NOT NULL UNIQUE,
    product_category_name VARCHAR(100),
    weight                INT,
    length                DECIMAL(10,2),
    height                DECIMAL(10,2),
    width                 DECIMAL(10,2)
);
GO

INSERT INTO dim_product (product_id, product_category_name, weight, length, height, width)
SELECT
    product_id,
    MAX(product_category_name),
    MAX(weight),
    MAX(length),
    MAX(height),
    MAX(width)
FROM dbo.olist_products_stg
GROUP BY product_id;
GO

/* ======================================
   SELLER
   ====================================== */
CREATE TABLE dim_seller (
    sk_seller       INT IDENTITY(1,1) PRIMARY KEY,
    seller_id       VARCHAR(50) NOT NULL UNIQUE,
    zip_code_prefix INT,
    sk_geo          INT NULL
);
GO

INSERT INTO dim_seller (seller_id, zip_code_prefix, sk_geo)
SELECT s.seller_id, s.zip_code_prefix, g.sk_geo
FROM (
    SELECT seller_id, zip_code_prefix,
           ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY seller_id) AS rn
    FROM dbo.olist_sellers_stg
) s
LEFT JOIN dim_geolocation g ON s.zip_code_prefix = g.zip_code_prefix
WHERE s.rn = 1;
GO

/* ======================================
   DATE
   ====================================== */
CREATE TABLE dbo.dim_date (
    date_key    INT PRIMARY KEY,
    full_date   DATE NOT NULL,
    year        INT  NOT NULL,
    month       INT  NOT NULL,
    day         INT  NOT NULL,
    anomes      INT  NOT NULL,
    anomesordem INT  NOT NULL
);
GO

DECLARE @DataInicial DATE = '2016-09-01';
DECLARE @DataFinal   DATE = '2018-10-31';

WITH calendario AS (
    SELECT @DataInicial AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date)
    FROM calendario
    WHERE full_date < @DataFinal
)
INSERT INTO dbo.dim_date (date_key, full_date, year, month, day, anomes, anomesordem)
SELECT
    YEAR(full_date) * 10000 + MONTH(full_date) * 100 + DAY(full_date),
    full_date,
    YEAR(full_date),
    MONTH(full_date),
    DAY(full_date),
    YEAR(full_date) * 100  + MONTH(full_date),
    YEAR(full_date) * 12   + MONTH(full_date)
FROM calendario
OPTION (MAXRECURSION 32767);
GO

/* =====================================================
   FATO 1 — VENDAS (GRÃO: ITEM DO PEDIDO)
   ===================================================== */
CREATE TABLE fact_sales (
    order_id                VARCHAR(32) NOT NULL,
    order_item_id           INT         NOT NULL,
    sk_customer             INT,
    sk_product              INT,
    sk_seller               INT,
    sk_geo                  INT,
    date_key                INT,
    purchase_date           DATETIME2,
    delivered_customer_date DATETIME2,
    estimated_delivery_date DATETIME2,
    order_status            VARCHAR(20),
    price                   DECIMAL(18,2),
    freight                 DECIMAL(18,2),
    CONSTRAINT PK_fact_sales PRIMARY KEY (order_id, order_item_id)
);
GO

INSERT INTO fact_sales (
    order_id, order_item_id, sk_customer, sk_product, sk_seller, sk_geo,
    date_key, purchase_date, delivered_customer_date, estimated_delivery_date,
    order_status, price, freight
)
SELECT
    oi.order_id,
    oi.order_item_id,
    dc.sk_customer,
    dp.sk_product,
    ds.sk_seller,
    COALESCE(ds.sk_geo, dc.sk_geo),
    YEAR(o.purchase_date) * 10000 + MONTH(o.purchase_date) * 100 + DAY(o.purchase_date),
    o.purchase_date,
    o.delivered_customer_date,
    o.estimated_delivery_date,
    o.order_status,
    oi.price,
    oi.freight
FROM dbo.olist_order_items_stg oi
JOIN dbo.olist_orders_stg o   ON oi.order_id   = o.order_id
LEFT JOIN dim_customer dc     ON o.customer_id  = dc.customer_id
LEFT JOIN dim_product  dp     ON oi.product_id  = dp.product_id
LEFT JOIN dim_seller   ds     ON oi.seller_id   = ds.seller_id;
GO

/* =====================================================
   FATO 2 — PAGAMENTO (GRÃO: PEDIDO)
   ===================================================== */
CREATE TABLE fact_payment (
    order_id      VARCHAR(32) PRIMARY KEY,
    sk_customer   INT,
    date_key      INT,
    payment_value DECIMAL(18,2)
);
GO

INSERT INTO fact_payment (order_id, sk_customer, date_key, payment_value)
SELECT
    p.order_id,
    dc.sk_customer,
    YEAR(o.purchase_date) * 10000 + MONTH(o.purchase_date) * 100 + DAY(o.purchase_date),
    p.payment_value
FROM dbo.olist_payments_stg p
JOIN dbo.olist_orders_stg o  ON p.order_id    = o.order_id
LEFT JOIN dim_customer dc    ON o.customer_id = dc.customer_id;
GO

/* =====================================================
   FOREIGN KEYS
   ===================================================== */
ALTER TABLE dim_customer
    ADD CONSTRAINT FK_dim_customer_geo
    FOREIGN KEY (sk_geo) REFERENCES dim_geolocation(sk_geo);
GO
ALTER TABLE dim_seller
    ADD CONSTRAINT FK_dim_seller_geo
    FOREIGN KEY (sk_geo) REFERENCES dim_geolocation(sk_geo);
GO
ALTER TABLE fact_sales
    ADD CONSTRAINT FK_sales_customer
    FOREIGN KEY (sk_customer) REFERENCES dim_customer(sk_customer);
GO
ALTER TABLE fact_sales
    ADD CONSTRAINT FK_sales_product
    FOREIGN KEY (sk_product) REFERENCES dim_product(sk_product);
GO
ALTER TABLE fact_sales
    ADD CONSTRAINT FK_sales_seller
    FOREIGN KEY (sk_seller) REFERENCES dim_seller(sk_seller);
GO
ALTER TABLE fact_sales
    ADD CONSTRAINT FK_sales_date
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key);
GO
ALTER TABLE fact_payment
    ADD CONSTRAINT FK_payment_customer
    FOREIGN KEY (sk_customer) REFERENCES dim_customer(sk_customer);
GO
ALTER TABLE fact_payment
    ADD CONSTRAINT FK_payment_date
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key);
GO
