-- 1. Kiểm định đềm Active Members theo tháng (Chứng minh Zero Churn Rate ~98.7K)
SELECT 
    MONTH(CAST(sales_date AS DATE)) AS [Month_Number],
    COUNT(DISTINCT customer_id) AS [Active_Customers],
    COUNT(DISTINCT transaction_number) AS [Total_Orders]
FROM fmcg_sales.sales
WHERE sales_date IS NOT NULL 
  AND MONTH(CAST(sales_date AS DATE)) IN (1, 2, 3, 4)
GROUP BY MONTH(CAST(sales_date AS DATE))
ORDER BY [Month_Number] ASC;

-- 2. Phân khúc khách hàng theo Chi tiêu Tứ phân vị (Dynamic Quartile Segmentation - NTILE 4)
WITH Spending_Records AS (
    SELECT 
        s.customer_id,
        ROUND(SUM(s.quantity * p.price * (1 - s.discount)), 2) AS [Total_Spend_USD]
    FROM fmcg_sales.sales s
    INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id
    WHERE s.sales_date IS NOT NULL 
      AND MONTH(CAST(s.sales_date AS DATE)) IN (1, 2, 3, 4)
    GROUP BY s.customer_id
),
Customer_Quartiles AS (
    SELECT 
        customer_id,
        [Total_Spend_USD],
        NTILE(4) OVER (ORDER BY [Total_Spend_USD] DESC) AS [Quartile]
    FROM Spending_Records
)
SELECT 
    CASE 
        WHEN [Quartile] = 1 THEN 'High Spenders (VIP)'
        WHEN [Quartile] = 2 THEN 'Medium-High Spenders'
        WHEN [Quartile] = 3 THEN 'Medium-Low Spenders'
        ELSE 'Low Spenders'
    END AS [Spending_Segment],
    COUNT(*) AS [Total_Customers],
    ROUND(SUM([Total_Spend_USD]), 2) AS [Segment_Total_Spend_USD],
    ROUND(AVG([Total_Spend_USD]), 2) AS [Avg_Spend_Per_Customer_USD]
FROM Customer_Quartiles
GROUP BY [Quartile]
ORDER BY [Quartile] ASC;

-- 3. Kiểm tra kỷ luật Chiết khấu của 23 Thu ngân (Cashier Discount Compliance ~3.00%)
SELECT 
    e.employee_id AS [Staff_Id],
    e.first_name + ' ' + e.last_name AS [Cashier_Name],
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)), 2) AS [Total_Revenue_USD],
    ROUND(AVG(s.discount) * 100, 4) AS [Avg_Discount_Given_%]
FROM fmcg_sales.sales s
INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id
INNER JOIN fmcg_sales.employees e ON s.salesperson_id = e.employee_id
WHERE s.sales_date IS NOT NULL 
  AND MONTH(CAST(s.sales_date AS DATE)) IN (1, 2, 3, 4)
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY [Total_Revenue_USD] DESC;
