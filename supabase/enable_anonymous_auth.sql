-- Enable anonymous authentication for development/testing
-- This allows sync to work without requiring Google OAuth setup
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/wppagoydvelahftjkgpx/sql

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Allow all authenticated users" ON products;
DROP POLICY IF EXISTS "Allow all authenticated users" ON customers;
DROP POLICY IF EXISTS "Allow all authenticated users" ON invoices;
DROP POLICY IF EXISTS "Allow all authenticated users" ON invoice_items;

-- Create new policies that allow both authenticated AND anonymous users
CREATE POLICY "Allow authenticated and anon users" ON products 
  FOR ALL 
  USING (auth.role() IN ('authenticated', 'anon')) 
  WITH CHECK (auth.role() IN ('authenticated', 'anon'));

CREATE POLICY "Allow authenticated and anon users" ON customers 
  FOR ALL 
  USING (auth.role() IN ('authenticated', 'anon')) 
  WITH CHECK (auth.role() IN ('authenticated', 'anon'));

CREATE POLICY "Allow authenticated and anon users" ON invoices 
  FOR ALL 
  USING (auth.role() IN ('authenticated', 'anon')) 
  WITH CHECK (auth.role() IN ('authenticated', 'anon'));

CREATE POLICY "Allow authenticated and anon users" ON invoice_items 
  FOR ALL 
  USING (auth.role() IN ('authenticated', 'anon')) 
  WITH CHECK (auth.role() IN ('authenticated', 'anon'));

-- Verify policies were created
SELECT schemaname, tablename, policyname, roles, qual, with_check
FROM pg_policies
WHERE tablename IN ('products', 'customers', 'invoices', 'invoice_items')
ORDER BY tablename, policyname;
