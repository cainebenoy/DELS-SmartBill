-- ============================================
-- TEST YOUR SYNC FUNCTIONS
-- Run these queries one by one in Supabase SQL Editor
-- ============================================

-- TEST 1: Check if get_server_timestamp works
-- Expected: Should return a big number like 1729450000000 (current time in milliseconds)
SELECT get_server_timestamp();


-- TEST 2: Check if fetch_products_since works
-- Expected: Should return all your products from the products table
SELECT * FROM fetch_products_since(0);


-- TEST 3: Check if fetch_customers_since works
-- Expected: Should return all your customers
SELECT * FROM fetch_customers_since(0);


-- TEST 4: Check if fetch_invoices_since works
-- Expected: Should return all your invoices
SELECT * FROM fetch_invoices_since(0);


-- TEST 5: Check if fetch_invoice_items_since works
-- Expected: Should return all your invoice items
SELECT * FROM fetch_invoice_items_since(0);


-- TEST 6: Check all products with their timestamps
-- This helps you see what timestamps your products have
SELECT 
  id, 
  name, 
  created_at, 
  updated_at,
  extract(epoch from updated_at) * 1000 as updated_at_millis
FROM products
ORDER BY updated_at DESC;


-- ============================================
-- If all these work without errors, your sync is ready!
-- ============================================
