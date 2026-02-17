--TASK 1A
--1
SELECT
    COUNT(DISTINCT store_id) AS total_stores,
    COUNT(DISTINCT city_id)     AS total_cities
FROM train_data;

--2
SELECT
    julianday(MAX(dt)) - julianday(MIN(dt)) AS days_diff
FROM train_data;

--3
SELECT 
	COUNT(DISTINCT product_id) as total_products
FROM train_data td 

SELECT
    COUNT(DISTINCT category_id) AS total_categories
FROM (
    SELECT first_category_id  AS category_id FROM train_data
    UNION
    SELECT second_category_id FROM train_data
    UNION
    SELECT third_category_id  FROM train_data
) t;

--TASK 1B
--4
SELECT
    SUM(sale_amount) AS total_sales_volume
FROM train_data;

--5
SELECT 
	AVG(hours_sale)
FROM train_data

--6
SELECT
    SUM(CASE WHEN hours_sale = 0 THEN 1 ELSE 0 END)     AS zero_sales_hours,
    SUM(CASE WHEN hours_sale > 0 THEN 1 ELSE 0 END)     AS non_zero_sales_hours
FROM train_data;

--TASK2A
--7
SELECT 
    SUBSTR("hours_sale", 1, 2) AS "hour_of_day",
    SUM("sale_amount") AS "total_sales"
FROM 
    "train_data"
WHERE "hours_sale" IS NOT NULL
GROUP BY "hour_of_day"
ORDER BY "total_sales" DESC;

--8
SELECT
    CAST(strftime('%w', dt) AS INTEGER) AS weekday_num,
    SUM(sale_amount) AS total_sales
FROM train_data
GROUP BY weekday_num
ORDER BY total_sales DESC;

--TASK 2B
--9
SELECT 
    holiday_flag,
    AVG(sale_amount) AS avg_sale_amount
FROM train_data
GROUP BY holiday_flag;

--10
SELECT 
    CASE 
        WHEN "precpt" > 0 THEN 'Rainy Days'
        ELSE 'Clear Days'
    END AS "Day_Type",
    AVG("sale_amount") AS "Average_Sale_Amount"
FROM "train_data"
GROUP BY "Day_Type";


--TASK3A
DROP VIEW IF EXISTS hourly_business_summary;
CREATE VIEW hourly_business_summary AS
SELECT
    "dt",
    strftime('%H', "dt") AS "hour", 
    strftime('%w', "dt") AS "day_of_week", 
    strftime('%m', "dt") AS "month", 
    CASE
        WHEN strftime('%w', "dt") IN ('0', '6') THEN 1 ELSE 0
    END AS "is_weekend", 
    CASE
        WHEN strftime('%H', "dt") BETWEEN '18' AND '23' THEN 1 ELSE 0
    END AS "is_evening",

    "store_id",
    "third_category_id", 
    "sale_amount",
    CASE
        WHEN "sale_amount" > 0 THEN 1 ELSE 0
    END AS "sale_occurred", 

    "stock_hour6_22_cnt",
    CASE
        WHEN "stock_hour6_22_cnt" = 0 THEN 1 ELSE 0
    END AS "stockout_flag", 
    
    "discount",
    CASE
        WHEN "discount" > 0 THEN 1 ELSE 0
    END AS "is_promotional", 
    "precpt",
    CASE
        WHEN "precpt" > 0 THEN 1 ELSE 0
    END AS "is_raining", 
    "avg_temperature",
    "avg_humidity",
    "avg_wind_level",

    CASE
        WHEN strftime('%w', "dt") IN ('0', '6') AND strftime('%H', "dt") BETWEEN '18' AND '23' THEN 1 ELSE 0
    END AS "is_weekend_evening", 

    CASE
        WHEN ("discount" > 0) AND ("precpt" > 0) THEN 1 ELSE 0
    END AS "is_promo_and_rain"
FROM train_data;
    

--TASK3B
CREATE VIEW store_performance_dashboard AS
SELECT
    -- Store Identifier
    store_id,

    -- Operational Scale
    COUNT(DISTINCT dt) AS operational_days,
    SUM(stock_hour6_22_cnt) AS total_stock_hours,

    -- Sales Performance
    SUM(sale_amount) AS total_sales,
    AVG(sale_amount) AS avg_sales_per_day, 
    SUM(sale_amount) / NULLIF(SUM(stock_hour6_22_cnt), 0) AS sales_per_stock_hour, 
    
    -- Inventory Management Effectiveness
    SUM(CASE WHEN stock_hour6_22_cnt = 0 THEN 1 ELSE 0 END) AS stockout_days, 
    SUM(CASE WHEN stock_hour6_22_cnt = 0 THEN sale_amount ELSE 0 END) AS lost_sales_due_to_stockouts, 
    AVG(stock_hour6_22_cnt) AS avg_stock_availability,

    -- Customer Engagement
    COUNT(CASE WHEN hours_sale IS NOT NULL THEN 1 END) AS active_hours, 
    SUM(sale_amount) / NULLIF(COUNT(CASE WHEN hours_sale IS NOT NULL THEN 1 END), 0) AS sales_per_active_hour,

    -- Promotional Effectiveness
    SUM(CASE WHEN discount > 0 THEN sale_amount ELSE 0 END) AS promo_sales, 
    SUM(CASE WHEN discount > 0 THEN sale_amount ELSE 0 END) / NULLIF(SUM(sale_amount), 0) AS promo_sales_ratio, 
    AVG(CASE WHEN discount > 0 THEN discount ELSE NULL END) AS avg_discount_during_promo,

    -- Consistency Indicators
    MAX(sale_amount) - MIN(sale_amount) AS sales_variability,
    COUNT(CASE WHEN sale_amount > 0 THEN 1 END) / NULLIF(COUNT(DISTINCT dt), 0) AS sales_consistency_ratio
FROM train_data
GROUP BY store_id;

--TASK3C
DROP VIEW IF EXISTS category_intelligence
CREATE VIEW category_intelligence AS
WITH category_metrics AS (
    SELECT
        third_category_id,
        COUNT(DISTINCT store_id) AS store_count, 
        SUM(sale_amount) AS total_sales, 
        AVG(sale_amount) AS avg_sales_per_store, 
        COUNT(sale_amount) AS sales_occurrences, 


        AVG(sale_amount) AS avg_sale_amount, 
        MAX(sale_amount) AS max_sale_amount,
        MIN(sale_amount) AS min_sale_amount, 
        (MAX(sale_amount) - MIN(sale_amount)) AS sale_variability,
       
        AVG(stock_hour6_22_cnt) AS avg_stock_level,
        SUM(CASE WHEN stock_hour6_22_cnt = 0 THEN 1 ELSE 0 END) AS stockout_count,
        SUM(CASE WHEN stock_hour6_22_cnt = 0 THEN sale_amount ELSE 0 END) AS lost_sales_due_to_stockout, 
        
        AVG(CASE WHEN discount > 0 THEN sale_amount ELSE NULL END) AS avg_sales_with_discount, 
        AVG(CASE WHEN holiday_flag = 1 THEN sale_amount ELSE NULL END) AS avg_sales_on_holidays,
        AVG(CASE WHEN precpt > 0 THEN sale_amount ELSE NULL END) AS avg_sales_on_rainy_days, 
        AVG(CASE WHEN avg_temperature < 10 THEN sale_amount ELSE NULL END) AS avg_sales_in_cold_weather, 
        AVG(CASE WHEN avg_temperature > 30 THEN sale_amount ELSE NULL END) AS avg_sales_in_hot_weather, 

        COUNT(DISTINCT dt) AS active_days, 
        COUNT(DISTINCT store_id) * COUNT(DISTINCT dt) AS store_day_combinations, 
        COUNT(sale_amount) * 1.0 / (COUNT(DISTINCT store_id) * COUNT(DISTINCT dt)) AS sales_density 
    FROM train_data
    GROUP BY third_category_id
)
SELECT
    cm.third_category_id,
    cm.store_count,
    cm.total_sales,
    cm.avg_sales_per_store,
    cm.sales_occurrences,
    cm.avg_sale_amount,
    cm.max_sale_amount,
    cm.min_sale_amount,
    cm.sale_variability,
    cm.avg_stock_level,
    cm.stockout_count,
    cm.lost_sales_due_to_stockout,
    cm.avg_sales_with_discount,
    cm.avg_sales_on_holidays,
    cm.avg_sales_on_rainy_days,
    cm.avg_sales_in_cold_weather,
    cm.avg_sales_in_hot_weather,
    cm.active_days,
    cm.store_day_combinations,
    cm.sales_density
FROM category_metrics cm;
        
        
--TASK3D
CREATE VIEW business_rhythm_patterns AS
SELECT
    "hour",
    day_of_week,
    "month",
    is_weekend,
    is_evening,
    AVG(sale_amount) AS avg_sale_amount,
    SUM(CASE WHEN sale_occurred = 1 THEN 1 ELSE 0 END) AS total_sales_occurrences,
    AVG(stock_hour6_22_cnt) AS avg_stock_level, 
    SUM(CASE WHEN stockout_flag = 1 THEN 1 ELSE 0 END) AS total_stockouts,
    AVG(discount) AS avg_discount,
    SUM(CASE WHEN is_promotional = 1 THEN 1 ELSE 0 END) AS total_promotions, 
    AVG(precpt) AS avg_precipitation,
    AVG(avg_temperature) AS avg_temperature, 
    AVG(avg_humidity) AS avg_humidity,
    AVG(avg_wind_level) AS avg_wind_level, 
    SUM(CASE WHEN is_weekend_evening = 1 THEN 1 ELSE 0 END) AS weekend_evening_count, 
    SUM(CASE WHEN is_promo_and_rain = 1 THEN 1 ELSE 0 END) AS promo_and_rain_count, 
    CASE
        WHEN AVG(sale_amount) > (SELECT AVG(sale_amount) FROM hourly_business_summary) THEN 'High Activity'
        WHEN AVG(sale_amount) BETWEEN (SELECT AVG(sale_amount) FROM hourly_business_summary) * 0.5 AND (SELECT AVG(sale_amount) FROM hourly_business_summary) THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_classification 
FROM hourly_business_summary
GROUP BY "hour", day_of_week, "month", is_weekend, is_evening;


--TASK4A
--11
SELECT 
    (CAST(SUM(CASE WHEN "stockout_flag" = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100 AS stockout_percentage
FROM "hourly_business_summary";

--12
SELECT 
    CASE 
        WHEN "stockout_flag" = 1 THEN 'Stocked-Out'
        ELSE 'In-Stock'
    END AS stock_status,
    AVG("sale_amount") AS avg_sale_amount
FROM "hourly_business_summary"
GROUP BY stock_status;

--13
SELECT 
    "third_category_id" AS product_id,
    AVG(CASE WHEN "stockout_flag" = 1 THEN 1 ELSE 0 END) AS stockout_rate
FROM hourly_business_summary
GROUP BY "third_category_id"
ORDER BY stockout_rate DESC
LIMIT 10;


--TASK4B
--14
SELECT 
    "hour",
    ROUND(SUM(CASE WHEN stockout_flag = 1 THEN 1 ELSE 0 END) * 1 / COUNT(*) * 100, 2) AS stockout_rate_percentage
FROM 
    hourly_business_summary
GROUP BY 
    "hour"
ORDER BY 
    "hour";

--15
SELECT 
    "store_id",
    AVG(CASE WHEN "stockout_flag" = 1 THEN 1 ELSE 0 END) AS stockout_rate
FROM 
    "hourly_business_summary"
GROUP BY 
    "store_id"
ORDER BY 
    stockout_rate DESC
LIMIT 5;


--TASK5A
--16
SELECT
    td.store_id,
    SUM(td.sale_amount) AS total_sales
FROM train_data td
GROUP BY td.store_id
ORDER BY total_sales DESC
LIMIT 10;

--17
SELECT 
    "city_id",
    SUM("sale_amount") AS total_sales,
    COUNT(DISTINCT "store_id") AS store_count,
    SUM("sale_amount") * 1.0 / COUNT(DISTINCT "store_id") AS avg_sales_per_store
FROM train_data td 
GROUP BY "city_id"
ORDER BY avg_sales_per_store DESC;

--18
WITH averages AS (
    SELECT 
        AVG("total_sales") AS avg_total_sales,
        AVG("stockout_days") AS avg_stockout_days
    FROM "store_performance_dashboard"
)
SELECT 
    "store_id",
    "total_sales",
    "stockout_days",
    "avg_sales_per_day",
    "sales_per_stock_hour",
    "lost_sales_due_to_stockouts",
    "avg_stock_availability"
FROM 
    "store_performance_dashboard",
    averages
WHERE 
    "total_sales" > averages.avg_total_sales
    AND "stockout_days" > averages.avg_stockout_days
ORDER BY "total_sales" DESC, "stockout_days" DESC;


--TASK5B
--19
SELECT
	third_category_id,
	SUM(sale_amount) AS total_sales
FROM train_data td 
GROUP BY third_category_id 
ORDER BY total_sales DESC

--20
WITH product_hourly_sales AS (
    SELECT
        "product_id",
        AVG("sale_amount" / (LENGTH("hours_sale") - LENGTH(REPLACE("hours_sale", ',', '')) + 1)) AS avg_hourly_sales
    FROM "train_data"
    WHERE "hours_sale" IS NOT NULL AND "hours_sale" != ''
    GROUP BY "product_id"
)
SELECT
    "product_id",
    avg_hourly_sales
FROM product_hourly_sales
ORDER BY avg_hourly_sales DESC;


--TASK6A
--21
SELECT 
    CASE 
        WHEN "discount" > 0 THEN 'Discounted Hours'
        ELSE 'Regular Price Hours'
    END AS price_type,
    AVG("sale_amount") AS avg_sale_amount
FROM train_data td 
GROUP BY price_type;

--22
SELECT 
    CASE 
        WHEN "discount" = 0 THEN '0%'
        WHEN "discount" > 0 AND "discount" <= 0.10 THEN '1-10%'
        WHEN "discount" > 0.10 AND "discount" <= 0.20 THEN '11-20%'
        ELSE '21%+'
    END AS discount_range,
    COUNT(*) AS sales_occurrences,
    SUM("sale_amount") AS total_sales,
    AVG("sale_amount") AS avg_sale_amount
FROM train_data td 
GROUP BY discount_range
ORDER BY total_sales DESC;

--23
SELECT 
    "third_category_id",
    COUNT(CASE WHEN "discount" > 0 THEN 1 END) AS "promo_occurrences",
    AVG(CASE WHEN "discount" > 0 THEN "sale_amount" END) AS "avg_sales_during_promo",
    AVG("sale_amount") AS "avg_sales_overall",
    (AVG(CASE WHEN "discount" > 0 THEN "sale_amount" END) - AVG("sale_amount")) AS "promo_effectiveness"
FROM 
    "train_data"
WHERE 
    "sale_amount" IS NOT NULL
GROUP BY 
    "third_category_id"
ORDER BY 
    "promo_effectiveness" DESC;


--TASK6B
--24
SELECT
    activity_flag,
    COUNT(*) AS total_hours,
    SUM(sale_amount) AS total_sales,
    AVG(sale_amount) AS avg_sales_per_hour
FROM train_data
GROUP BY activity_flag;

--25
SELECT 
    CASE 
        WHEN "is_promotional" = 1 THEN 'Promotional'
        ELSE 'Non-Promotional'
    END AS promotion_status,
    AVG("sale_amount") AS avg_sale_during_stockout
FROM "hourly_business_summary"
WHERE "stockout_flag" = 1
GROUP BY "is_promotional";


--TASK7A
--26
SELECT
    store_id,
    third_category_id,

    COUNT(*) AS total_hours,
    SUM(sale_amount) AS total_sales,
    AVG(sale_amount) AS avg_hourly_sales,

    SUM(stockout_flag) AS stockout_hours,
    SUM(stockout_flag) * 1.0 / COUNT(*) AS stockout_rate,

    SUM(CASE 
            WHEN stockout_flag = 1 AND sale_occurred = 0 
            THEN 1 ELSE 0 
        END) AS lost_sales_hours

FROM hourly_business_summary
GROUP BY store_id, third_category_id
HAVING 
    AVG(sale_amount) > (
        SELECT AVG(sale_amount) FROM hourly_business_summary
    )
    AND
    SUM(stockout_flag) * 1.0 / COUNT(*) > 0.15
ORDER BY avg_hourly_sales DESC;

--27
SELECT
    third_category_id,

    AVG(CASE WHEN is_raining = 1 THEN sale_amount END) AS avg_sales_rain,

    AVG(CASE WHEN is_raining = 0 THEN sale_amount END) AS avg_sales_no_rain,

    CASE
        WHEN AVG(CASE WHEN is_raining = 0 THEN sale_amount END) > 0
        THEN
            (
                AVG(CASE WHEN is_raining = 1 THEN sale_amount END)
                -
                AVG(CASE WHEN is_raining = 0 THEN sale_amount END)
            )
            /
            AVG(CASE WHEN is_raining = 0 THEN sale_amount END)
        ELSE NULL
    END AS rain_impact_ratio

FROM hourly_business_summary
GROUP BY third_category_id
ORDER BY rain_impact_ratio DESC;

--TASK7B
--28
SELECT 
	"hour", SUM(sale_amount) AS total_sales
FROM "hourly_business_summary"
GROUP BY "hour"
ORDER BY total_sales DESC
LIMIT 5; 

SELECT 
	product_id, COUNT(*) AS stockout_occurrences
FROM "train_data"
WHERE "hour" IN ('10', '11', '12', '13', '14') AND stock_hour6_22_cnt = 0
GROUP BY product_id
ORDER BY stockout_occurrences DESC;

--29
SELECT 
    "store_id", 
    SUM(lost_sales_due_to_stockouts) AS potential_sales_increase
FROM store_performance_dashboard
GROUP BY "store_id";

--30
SELECT 
    "store_id",
    (COALESCE(total_sales, 0) * 0.5 + 
     COALESCE(avg_sales_per_day, 0) * 0.3 - 
     COALESCE(stockout_days, 0) * 0.1 + 
     COALESCE(avg_stock_availability, 0) * 0.1) AS store_health_score
FROM store_performance_dashboard;










