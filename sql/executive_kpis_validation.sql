-- 1. Xác nhận KPI tổng quan 4 tháng hợp lệ ($3.99Bn Revenue, 6.22M Orders, $641 AOV)
SELECT 
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)), 2) AS [Total_Revenue_USD],
    COUNT(DISTINCT s.transaction_number) AS [Total_Orders],
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)) / COUNT(DISTINCT s.transaction_number), 2) AS [AOV_System_USD]
FROM fmcg_sales.sales s
INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id
WHERE s.sales_date IS NOT NULL 
  AND MONTH(CAST(s.sales_date AS DATE)) IN (1, 2, 3, 4);

-- 2. Phân tich chất lượng dòng tiền (Full Price 82.48% vs Discounted Items 17.52%)
SELECT 
    CASE WHEN s.discount = 0 THEN 'Full Price Items' ELSE 'Discounted Items' END AS [Sales_Type],
    COUNT(*) AS [Total_Lines_Sold],
    SUM(s.quantity) AS [Total_Quantity],
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)), 2) AS [Net_Revenue_USD],
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)) * 100.0 / SUM(SUM(s.quantity * p.price * (1 - s.discount))) OVER(), 2) AS [Contribution_%]
FROM fmcg_sales.sales s
INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id
WHERE s.sales_date IS NOT NULL 
  AND MONTH(CAST(s.sales_date AS DATE)) IN (1, 2, 3, 4)
GROUP BY CASE WHEN s.discount = 0 THEN 'Full Price Items' ELSE 'Discounted Items' END;

-- 3. Top thành phố dẫn đầu về Doanh thu & AOV kỷ lục (Tucson & Jackson)
SELECT 
    ci.city_name AS [City_Name],
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)), 2) AS [Total_Revenue_USD],
    COUNT(DISTINCT s.transaction_number) AS [Total_Orders],
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)) / COUNT(DISTINCT s.transaction_number), 2) AS [City_AOV_USD]
FROM fmcg_sales.sales s
INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id
INNER JOIN fmcg_sales.customers cu ON s.customer_id = cu.customer_id
INNER JOIN fmcg_sales.cities ci ON cu.city_id = ci.city_id
WHERE s.sales_date IS NOT NULL 
  AND MONTH(CAST(s.sales_date AS DATE)) IN (1, 2, 3, 4)
GROUP BY ci.city_name
ORDER BY [Total_Revenue_USD] DESC;
