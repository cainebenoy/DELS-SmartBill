-- ============================================
-- COMPLETE SYNC FIX FOR DELS SMARTBILL
-- Run this in Supabase SQL Editor to fix all sync issues
-- ============================================

-- 1. CREATE SERVER TIMESTAMP FUNCTION (returns milliseconds as BIGINT)
CREATE OR REPLACE FUNCTION public.get_server_timestamp()
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
  SELECT (extract(epoch from now()) * 1000)::bigint;
$$;

GRANT EXECUTE ON FUNCTION public.get_server_timestamp() TO authenticated, anon;


-- 2. DROP OLD FETCH FUNCTIONS (in case they exist with wrong signature)
DROP FUNCTION IF EXISTS public.fetch_products_since(timestamptz);
DROP FUNCTION IF EXISTS public.fetch_customers_since(timestamptz);
DROP FUNCTION IF EXISTS public.fetch_invoices_since(timestamptz);
DROP FUNCTION IF EXISTS public.fetch_invoice_items_since(timestamptz);


-- 3. CREATE NEW FETCH FUNCTIONS (accept milliseconds as BIGINT)
CREATE OR REPLACE FUNCTION public.fetch_products_since(since_timestamp BIGINT)
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

GRANT EXECUTE ON FUNCTION public.fetch_products_since(BIGINT) TO authenticated, anon;


CREATE OR REPLACE FUNCTION public.fetch_customers_since(since_timestamp BIGINT)
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

GRANT EXECUTE ON FUNCTION public.fetch_customers_since(BIGINT) TO authenticated, anon;


CREATE OR REPLACE FUNCTION public.fetch_invoices_since(since_timestamp BIGINT)
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

GRANT EXECUTE ON FUNCTION public.fetch_invoices_since(BIGINT) TO authenticated, anon;


CREATE OR REPLACE FUNCTION public.fetch_invoice_items_since(since_timestamp BIGINT)
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

GRANT EXECUTE ON FUNCTION public.fetch_invoice_items_since(BIGINT) TO authenticated, anon;


-- 4. ENSURE TRIGGERS FIRE ON INSERT (for products created in Supabase UI)
-- Replace existing trigger function with one that works on INSERT too
CREATE OR REPLACE FUNCTION public.set_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Set updated_at on both INSERT and UPDATE
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Recreate triggers to fire on INSERT OR UPDATE
DROP TRIGGER IF EXISTS set_timestamp_products ON products;
CREATE TRIGGER set_timestamp_products
  BEFORE INSERT OR UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION public.set_timestamp();

DROP TRIGGER IF EXISTS set_timestamp_customers ON customers;
CREATE TRIGGER set_timestamp_customers
  BEFORE INSERT OR UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_timestamp();

DROP TRIGGER IF EXISTS set_timestamp_invoices ON invoices;
CREATE TRIGGER set_timestamp_invoices
  BEFORE INSERT OR UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION public.set_timestamp();

DROP TRIGGER IF EXISTS set_timestamp_invoice_items ON invoice_items;
CREATE TRIGGER set_timestamp_invoice_items
  BEFORE INSERT OR UPDATE ON invoice_items
  FOR EACH ROW
  EXECUTE FUNCTION public.set_timestamp();


-- 5. VERIFY DEFAULT VALUES (ensure all timestamps get set even if trigger doesn't fire)
-- These are already in schema but let's be explicit
ALTER TABLE products ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE products ALTER COLUMN updated_at SET DEFAULT now();

ALTER TABLE customers ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE customers ALTER COLUMN updated_at SET DEFAULT now();

ALTER TABLE invoices ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE invoices ALTER COLUMN updated_at SET DEFAULT now();

ALTER TABLE invoice_items ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE invoice_items ALTER COLUMN updated_at SET DEFAULT now();


-- ============================================
-- DONE! Your sync should now work correctly.
-- ============================================
-- To test:
-- 1. Run: SELECT get_server_timestamp();  -- Should return a big number (milliseconds)
-- 2. Run: SELECT * FROM fetch_products_since(0);  -- Should return all products
-- 3. Add a product in Supabase UI, then sync in your app - it should appear!
