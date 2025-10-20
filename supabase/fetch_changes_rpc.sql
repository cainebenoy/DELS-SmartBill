-- RPC Functions for Fetching Changes Since Last Sync
-- These functions return all records modified after a given timestamp
-- Used by the mobile app to pull changes from Supabase

-- ============================================
-- FETCH PRODUCTS SINCE TIMESTAMP
-- ============================================
CREATE OR REPLACE FUNCTION fetch_products_since(since_timestamp BIGINT)
RETURNS SETOF products
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM products
  WHERE updated_at > to_timestamp(since_timestamp / 1000.0)
  ORDER BY updated_at ASC;
END;
$$;

-- Grant access to authenticated and anon users
GRANT EXECUTE ON FUNCTION fetch_products_since(BIGINT) TO authenticated, anon;


-- ============================================
-- FETCH CUSTOMERS SINCE TIMESTAMP
-- ============================================
CREATE OR REPLACE FUNCTION fetch_customers_since(since_timestamp BIGINT)
RETURNS SETOF customers
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM customers
  WHERE updated_at > to_timestamp(since_timestamp / 1000.0)
  ORDER BY updated_at ASC;
END;
$$;

-- Grant access to authenticated and anon users
GRANT EXECUTE ON FUNCTION fetch_customers_since(BIGINT) TO authenticated, anon;


-- ============================================
-- FETCH INVOICES SINCE TIMESTAMP
-- ============================================
CREATE OR REPLACE FUNCTION fetch_invoices_since(since_timestamp BIGINT)
RETURNS SETOF invoices
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM invoices
  WHERE updated_at > to_timestamp(since_timestamp / 1000.0)
  ORDER BY updated_at ASC;
END;
$$;

-- Grant access to authenticated and anon users
GRANT EXECUTE ON FUNCTION fetch_invoices_since(BIGINT) TO authenticated, anon;


-- ============================================
-- FETCH INVOICE ITEMS SINCE TIMESTAMP
-- ============================================
CREATE OR REPLACE FUNCTION fetch_invoice_items_since(since_timestamp BIGINT)
RETURNS SETOF invoice_items
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM invoice_items
  WHERE updated_at > to_timestamp(since_timestamp / 1000.0)
  ORDER BY updated_at ASC;
END;
$$;

-- Grant access to authenticated and anon users
GRANT EXECUTE ON FUNCTION fetch_invoice_items_since(BIGINT) TO authenticated, anon;


-- ============================================
-- USAGE NOTES
-- ============================================
-- Run this SQL in your Supabase SQL Editor to create the RPC functions
-- 
-- The functions:
-- - Accept a timestamp in milliseconds (Dart's DateTime.millisecondsSinceEpoch)
-- - Convert to PostgreSQL timestamp for comparison
-- - Return all records updated after that timestamp
-- - Order by updated_at ASC so client processes changes chronologically
-- - Use SECURITY DEFINER to bypass RLS (functions have GRANT permissions)
-- 
-- To call from Dart:
--   final data = await supabase.rpc('fetch_products_since', params: {'since_timestamp': lastSync});
-- 
-- To test in SQL Editor:
--   SELECT * FROM fetch_products_since(0);  -- Fetch all products
--   SELECT * FROM fetch_products_since(1704067200000);  -- Fetch products since 2024-01-01
