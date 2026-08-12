-- 1. Kiểm tra số dòng lỗi NULL ngày giao dịch và doanh thu bị hụt
SELECT 
    COUNT(CASE WHEN s.sales_date IS NULL THEN 1 END) AS [So_Dong_NULL],
    ROUND(SUM(CASE WHEN s.sales_date IS NULL THEN s.quantity * p.price * (1 - s.discount) END), 2) AS [Doanh_Thu_NULL_USD],
    ROUND(SUM(s.quantity * p.price * (1 - s.discount)), 2) AS [Tong_Doanh_Thu_Tho_USD]
FROM fmcg_sales.sales s
INNER JOIN fmcg_sales.products p ON s.product_id = p.product_id;

-- 2. Kiểm tra các hóa đơn bị NULL ngày nhưng có thể cứu dữ liệu (Transaction Matching)
SELECT 
    COUNT(DISTINCT s_null.transaction_number) AS [So_Hoa_Don_Nguy_Co_Mat],
    COUNT(DISTINCT s_valid.transaction_number) AS [So_Hoa_Don_Cuu_Duoc_Ngay]
FROM fmcg_sales.sales s_null
INNER JOIN fmcg_sales.sales s_valid 
    ON s_null.transaction_number = s_valid.transaction_number
WHERE s_null.sales_date IS NULL 
  AND s_valid.sales_date IS NOT NULL;

-- 3. Phát hiện danh mục sản phẩm bị khuyết Category (Category ID IS NULL)
SELECT 
    product_id, 
    product_name, 
    price,
    category_id
FROM fmcg_sales.products
WHERE category_id IS NULL 
   OR category_id NOT IN (SELECT category_id FROM fmcg_sales.categories);
