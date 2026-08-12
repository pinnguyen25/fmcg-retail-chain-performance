-- 1. Ma trận Ngành hàng: Doanh thu, Sản lượng & Hạn lưu kho trung bình (Vitality Days)
SELECT 
    c.category_name AS [Category],
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)), 2) AS [Total_Revenue_USD],
    SUM(s.quantity) AS [Total_Quantity_Sold],
    ROUND(AVG(CAST(p.vitality_days AS FLOAT)), 1) AS [Avg_Vitality_Days]
FROM fmcg_sales.sales s
INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id
INNER JOIN fmcg_sales.categories c ON p.category_id = c.category_id
WHERE s.sales_date IS NOT NULL 
  AND MONTH(CAST(s.sales_date AS DATE)) IN (1, 2, 3, 4)
GROUP BY c.category_name
ORDER BY [Total_Revenue_USD] DESC;

-- 2. Chẩn đoán biến động MoM giữa Tháng 1 và Tháng 2 (Phát hiện điểm gãy Ngành Confections & Meat)
SELECT 
    c.category_name AS [Category],
    SUM(CASE WHEN MONTH(CAST(s.sales_date AS DATE)) = 1 THEN s.quantity ELSE 0 END) AS [Jan_Qty],
    SUM(CASE WHEN MONTH(CAST(s.sales_date AS DATE)) = 2 THEN s.quantity ELSE 0 END) AS [Feb_Qty],
    (SUM(CASE WHEN MONTH(CAST(s.sales_date AS DATE)) = 2 THEN s.quantity ELSE 0 END) - 
     SUM(CASE WHEN MONTH(CAST(s.sales_date AS DATE)) = 1 THEN s.quantity ELSE 0 END)) AS [Quantity_Change_MoM],
    ROUND(SUM(CASE WHEN MONTH(CAST(s.sales_date AS DATE)) = 2 THEN s.quantity * p.price * (1 - s.discount) ELSE 0 END) - 
          SUM(CASE WHEN MONTH(CAST(s.sales_date AS DATE)) = 1 THEN s.quantity * p.price * (1 - s.discount) ELSE 0 END), 2) AS [Revenue_Change_MoM_USD]
FROM fmcg_sales.sales s
INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id
INNER JOIN fmcg_sales.categories c ON p.category_id = c.category_id
WHERE s.sales_date IS NOT NULL 
  AND MONTH(CAST(s.sales_date AS DATE)) IN (1, 2)
GROUP BY c.category_name
ORDER BY [Revenue_Change_MoM_USD] ASC;

-- 3. Top 5 SKUs bán chạy nhất theo từng Ngành hàng (Dùng cho Report Page Tooltip)
WITH Product_Revenue_Ranked AS (
    SELECT 
        c.category_name AS [Category_Name],
        p.product_name AS [Product_Name],
        ROUND(SUM(s.quantity * p.price * (1 - s.discount)), 2) AS [Product_Revenue_USD],
        SUM(s.quantity) AS [Product_Quantity],
        DENSE_RANK() OVER (
            PARTITION BY c.category_name 
            ORDER BY SUM(s.quantity * p.price * (1 - s.discount)) DESC
        ) AS [Product_Rank]
    FROM fmcg_sales.sales s
    INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id
    INNER JOIN fmcg_sales.categories c ON p.category_id = c.category_id
    WHERE s.sales_date IS NOT NULL 
      AND MONTH(CAST(s.sales_date AS DATE)) IN (1, 2, 3, 4)
    GROUP BY c.category_name, p.product_name
)
SELECT [Category_Name], [Product_Rank], [Product_Name], [Product_Revenue_USD], [Product_Quantity]
FROM Product_Revenue_Ranked
WHERE [Product_Rank] <= 5
ORDER BY [Category_Name] ASC, [Product_Rank] ASC;
