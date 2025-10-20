# Supabase Deployment Checklist

**Project:** DELS SmartBill  
**Supabase URL:** https://wppagoydvelahftjkgpx.supabase.co  
**Date:** October 20, 2025

---

## ✅ Required Components

### 1. Database Tables

Run `schema.sql` to create:

- [ ] `products` table
- [ ] `customers` table  
- [ ] `invoices` table
- [ ] `invoice_items` table

**Verification SQL:**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('products', 'customers', 'invoices', 'invoice_items');
```

Expected: 4 rows

---

### 2. RPC Functions

Run `fetch_changes_rpc.sql` to create:

- [ ] `fetch_products_since(BIGINT)`
- [ ] `fetch_customers_since(BIGINT)`
- [ ] `fetch_invoices_since(BIGINT)`
- [ ] `fetch_invoice_items_since(BIGINT)`

**Verification SQL:**
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE 'fetch_%_since';
```

Expected: 4 rows

**Test RPC Function:**
```sql
-- Should return all products
SELECT * FROM fetch_products_since(0);
```

---

### 3. Row Level Security (RLS) Policies

Check RLS is enabled and policies exist:

```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('products', 'customers', 'invoices', 'invoice_items');
```

Expected: All tables have rowsecurity = true

```sql
-- Check policies exist
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public';
```

Expected: Policies for SELECT, INSERT, UPDATE, DELETE on each table

---

### 4. Triggers and Functions

Run `schema.sql` to create:

- [ ] `update_updated_at_column()` function
- [ ] Triggers on all tables to auto-update `updated_at`
- [ ] `assign_invoice_number()` function  
- [ ] Trigger on invoices to auto-assign invoice_number

**Verification:**
```sql
-- Check triggers
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public';
```

Expected: Triggers for updated_at on all tables, invoice_number trigger

---

### 5. Test Data (Optional)

Insert sample data for testing:

```sql
-- Insert test product
INSERT INTO products (id, name, category, price)
VALUES (
  'test-product-001',
  'Supabase Test Product',
  'Test',
  99.99
);

-- Verify it appears
SELECT * FROM products WHERE id = 'test-product-001';
```

---

## 🧪 Testing from App

### Test Push Sync

1. Open app
2. Create a product
3. Go to Settings → Sync Now
4. Check Supabase Table Editor → products table
5. Verify product appears

### Test Pull Sync

1. In Supabase, manually insert a product
2. In app, Settings → Sync Now
3. Go to Products tab
4. Verify product appears

### Check Console Logs

Should see:
```
✅ [SyncService] Push sync completed successfully
✅ [SyncService] Pull sync completed successfully
✅ [SyncService] Fetched N products from Supabase
```

---

## ⚠️ Common Issues

### Issue: RPC Functions Not Found

**Symptom:** Error calling `fetch_products_since`

**Solution:** Run `fetch_changes_rpc.sql` in SQL Editor

### Issue: Permission Denied

**Symptom:** 403 errors when syncing

**Solution:** Check RLS policies, ensure they allow authenticated/anon access

### Issue: No Data Syncing

**Symptom:** Sync completes but no data transferred

**Solution:** 
1. Check `isDirty` flag is set on local records
2. Verify lastSync timestamp is reasonable
3. Check Supabase has data

---

## 📋 Final Checklist

Before marking Task 2 complete:

- [ ] All 4 tables exist in Supabase
- [ ] All 4 RPC functions deployed
- [ ] RLS policies configured
- [ ] Triggers working (updated_at auto-updates)
- [ ] Invoice numbering trigger working
- [ ] Push sync works (local → Supabase)
- [ ] Pull sync works (Supabase → local)
- [ ] Conflict resolution tested
- [ ] Soft deletes working
- [ ] Multi-device sync tested (if possible)
- [ ] All 10 tests in BIDIRECTIONAL_SYNC_TEST.md passed

---

**Deployment Status:** ☐ Complete  ☐ Partial  ☐ Not Started

**Notes:**
