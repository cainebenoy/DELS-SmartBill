-- Clean Up All Data from Supabase Tables
-- Run this in Supabase SQL Editor to delete all test data
-- WARNING: This will delete ALL data in these tables!

-- Delete all invoice items first (due to foreign key constraints)
DELETE FROM invoice_items;

-- Delete all invoices
DELETE FROM invoices;

-- Delete all customers
DELETE FROM customers;

-- Delete all products
DELETE FROM products;

-- Verify tables are empty
SELECT 'products' as table_name, COUNT(*) as count FROM products
UNION ALL
SELECT 'customers' as table_name, COUNT(*) as count FROM customers
UNION ALL
SELECT 'invoices' as table_name, COUNT(*) as count FROM invoices
UNION ALL
SELECT 'invoice_items' as table_name, COUNT(*) as count FROM invoice_items;

-- You should see all counts as 0
