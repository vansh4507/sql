SELECT * FROM ev_data
--countries which have shown highest growth from 2015 to 2023
WITH cte AS(
SELECT region,
	SUM(CASE WHEN year = '2015' THEN value ELSE 0 END) AS Sales_2015,
	SUM(CASE WHEN year = '2023' THEN value ELSE 0 END) AS Sales_2023
FROM ev_data
WHERE parameter = 'EV sales'
GROUP BY region
),cte2 AS(
SELECT *,
	 ROUND(((Sales_2023 - Sales_2015)*100/NULLIF(Sales_2015,0))::numeric,2) as percent_growth
FROM cte
WHERE sales_2015 > 0)
SELECT * FROM cte2
ORDER BY percent_growth ASC
LIMIT 10

--for the year to year which country had highest region had highest sales
WITH cte AS(SELECT year,region,value,
	ROW_NUMBER() OVER(PARTITION BY year ORDER BY value DESC) as rn
FROM ev_data
WHERE parameter ='EV sales'
)
SELECT * FROM cte
WHERE rn =1
AND YEAR BETWEEN 2010 AND 2023

--Countries with the sharpest single-year spike in EV sales
WITH yearly_sales AS (
  SELECT
    region,
    year,
    SUM(value) AS total_sales
  FROM ev_data
  WHERE parameter = 'EV sales'
  GROUP BY region, year
),
growth_calc AS (
  SELECT
    region,
    year,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY region ORDER BY year) AS prev_sales
  FROM yearly_sales
),
growth_pct AS (
  SELECT
    region,
    year,
    total_sales,
    prev_sales,
    ROUND((((total_sales - prev_sales) * 100.0) / NULLIF(prev_sales, 0))::numeric, 2) AS sales_pct_growth
  FROM growth_calc
  WHERE prev_sales IS NOT NULL
)
SELECT *
FROM growth_pct
WHERE prev_sales > 10000 AND year BETWEEN 2018 AND 2023
ORDER BY sales_pct_growth DESC
LIMIT 10;

--EV Sales Share by Mode for the year 2023
WITH base AS (
  SELECT mode, SUM(value) AS total_share
  FROM ev_data
  WHERE parameter = 'EV sales share'
    AND year = 2023
  GROUP BY mode
),
total_sum AS (
  SELECT SUM(total_share) AS grand_total FROM base
)
SELECT 
  b.mode,
  ROUND(((b.total_share / t.grand_total) * 100)::Numeric, 2) AS share_percent
FROM base b, total_sum t
ORDER BY share_percent DESC;

--EV Sales By Continent 
SELECT continent,ROUND(SUM(value)::numeric,2) AS EV_Sales
FROM ev_data
WHERE parameter = 'EV sales'
GROUP BY continent


