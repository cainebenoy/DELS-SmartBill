# Bidirectional Sync Testing Guide

**Date:** October 20, 2025  
**Status:** Ready for Testing  
**Tester:** Manual Testing Required

---

## 🎯 Overview

This document provides step-by-step instructions to thoroughly test the bidirectional synchronization between local Floor database and Supabase cloud database. The tests verify push sync, pull sync, and conflict resolution across all entities.

---

## ✅ Pre-Test Checklist

### Requirements
- [ ] Supabase project is accessible and configured
- [ ] RPC functions deployed (`fetch_products_since`, etc.)
- [ ] At least 2 devices or ability to clear local DB between tests
- [ ] Internet connection available
- [ ] App running with Supabase credentials configured

### Initial Verification
```bash
# Run app with credentials
flutter run -d windows \
  --dart-define=SUPABASE_URL=https://wppagoydvelahftjkgpx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

Check console logs for:
```
✅ [SyncService] Push sync completed successfully
✅ [SyncService] Pull sync completed successfully
```

---

## 📝 Test Scenarios

### Test 1: Basic Push Sync (Local → Supabase)

**Objective:** Verify local changes are pushed to Supabase

**Steps:**
1. **Create a new product:**
   - Open Products tab
   - Click + button
   - Fill in: Name="Test Product A", Category="Test", Price=99.99
   - Click Save
   
2. **Trigger sync:**
   - Go to Settings tab
   - Click "Sync Now" button
   - Wait for "Sync completed" message

3. **Verify in Supabase:**
   - Open Supabase Dashboard → Table Editor
   - Go to `products` table
   - Verify "Test Product A" exists with correct data

**Expected Result:**
- ✅ Product appears in Supabase with same ID, name, category, price
- ✅ Console logs: `[SyncService] Pushed product: Test Product A`
- ✅ `isDirty` flag cleared locally

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 2: Basic Pull Sync (Supabase → Local)

**Objective:** Verify remote changes are pulled to local DB

**Steps:**
1. **Add data directly in Supabase:**
   - Open Supabase Dashboard → Table Editor
   - Go to `products` table
   - Click "Insert row"
   - Fill in:
     - id: Generate UUID (use https://www.uuidgenerator.net/)
     - name: "Test Product B"
     - category: "Test"
     - price: 149.99
     - created_at: now()
     - updated_at: now()
   - Save

2. **Trigger sync in app:**
   - Go to Settings → Click "Sync Now"
   
3. **Verify in app:**
   - Go to Products tab
   - Search for "Test Product B"
   - Verify it appears with correct data

**Expected Result:**
- ✅ Product appears in local DB with all fields
- ✅ Console logs: `[SyncService] Inserted new product: Test Product B`
- ✅ Product visible in Products list

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 3: Update Sync (Modify Existing Record)

**Objective:** Verify updates are synced bidirectionally

#### Part A: Local → Remote Update
1. **Modify local product:**
   - Go to Products tab
   - Find "Test Product A"
   - Click edit icon
   - Change price from 99.99 to 129.99
   - Save

2. **Sync and verify:**
   - Settings → Sync Now
   - Check Supabase: price should be 129.99
   - Check `updated_at` timestamp changed

#### Part B: Remote → Local Update
1. **Modify in Supabase:**
   - Find "Test Product B" in Supabase
   - Edit: Change category from "Test" to "Test Updated"
   - Save

2. **Sync and verify:**
   - App → Settings → Sync Now
   - Products tab → Find "Test Product B"
   - Category should be "Test Updated"

**Expected Result:**
- ✅ Both directions sync successfully
- ✅ Console logs show updates
- ✅ Timestamps updated correctly

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 4: Conflict Resolution (Same Record Modified on Both Sides)

**Objective:** Verify last-write-wins conflict resolution

**Setup:**
- Ensure you have "Test Product A" locally and in Supabase
- Note current updated_at timestamp

**Steps:**
1. **Simulate conflict:**
   - In Supabase: Change price to 200.00, save (this sets updated_at to now)
   - In App (DO NOT SYNC YET): Change price to 150.00, save
   
2. **Attempt sync:**
   - Settings → Sync Now
   - Watch console logs

3. **Check result:**
   - Locally: What price shows?
   - Supabase: What price shows?
   - Compare updated_at timestamps

**Expected Result:**
- ✅ Last-write-wins: Most recent `updated_at` takes precedence
- ✅ Console logs: Either "Updated product" or "Skipped product (local newer)"
- ✅ Both DB and Supabase have same final state

**Expected Behavior:**
```
Scenario A: Remote updated_at > Local updated_at
→ Pull overwrites local with remote (price = 200.00)

Scenario B: Local updated_at > Remote updated_at  
→ Pull skips remote, push overwrites remote (price = 150.00)
```

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 5: Soft Delete Sync

**Objective:** Verify deleted records are synced as soft deletes

**Steps:**
1. **Delete locally:**
   - Products tab → Find "Test Product A"
   - Swipe left or click delete
   - Confirm deletion

2. **Sync:**
   - Settings → Sync Now
   
3. **Verify in Supabase:**
   - Products table → Filter: deleted_at IS NOT NULL
   - "Test Product A" should have deleted_at timestamp
   - Record still exists in DB (soft delete)

4. **Pull to another device:**
   - If testing on second device, sync there
   - Product should disappear from list (isDeleted=true)

**Expected Result:**
- ✅ Record not actually deleted from Supabase
- ✅ `deleted_at` timestamp set
- ✅ Product hidden from app UI
- ✅ Console logs: `Soft deleted product: Test Product A`

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 6: Customer Sync

**Objective:** Verify customers sync correctly

**Steps:**
1. **Create customer locally:**
   - New Invoice page or Customers page
   - Add new customer: Name="Test Customer A", Phone="1234567890"
   - Save

2. **Sync to Supabase:**
   - Settings → Sync Now
   - Verify in `customers` table

3. **Create customer in Supabase:**
   - Insert: Name="Test Customer B"
   - Sync in app
   - Verify appears in Customers list

4. **Update customer:**
   - Change name in app → sync → verify in Supabase
   - Change name in Supabase → sync → verify in app

**Expected Result:**
- ✅ All operations succeed
- ✅ Timestamps correct
- ✅ Conflict resolution works

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 7: Invoice + Items Sync (Complex Relationships)

**Objective:** Verify invoices with line items sync correctly

**Steps:**
1. **Create invoice locally:**
   - Go to Invoice tab → Click + button
   - Select customer
   - Add 2 products to cart
   - Save invoice

2. **Sync:**
   - Settings → Sync Now
   
3. **Verify in Supabase:**
   - Check `invoices` table: Invoice should exist
   - Check `invoice_items` table: 2 items should exist with correct invoice_id
   - Verify foreign keys match

4. **Create invoice in Supabase:**
   - Manually insert invoice record
   - Insert 2 invoice_items referencing that invoice
   - Sync in app
   - Verify invoice shows in Reports with correct items

**Expected Result:**
- ✅ Invoice and items sync as a unit
- ✅ Foreign key relationships preserved
- ✅ Total amount matches sum of line items

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 8: Multi-Device Sync

**Objective:** Verify sync works between multiple devices

**Requirements:**
- 2 devices OR ability to clear local DB and re-install

**Steps:**
1. **Device A: Create data:**
   - Add 3 products
   - Add 2 customers
   - Create 1 invoice
   - Sync to Supabase

2. **Device B: Pull data:**
   - Fresh install or cleared DB
   - Open app
   - Settings → Sync Now
   - Verify all data appears

3. **Device B: Modify data:**
   - Update a product
   - Add a new customer
   - Sync to Supabase

4. **Device A: Pull changes:**
   - Settings → Sync Now
   - Verify updates from Device B appear

**Expected Result:**
- ✅ All data syncs correctly between devices
- ✅ No data loss
- ✅ Timestamps and IDs match

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 9: Incremental Sync (Only Changed Records)

**Objective:** Verify sync fetches only changed records, not full dataset

**Setup:**
- Have 10+ products in Supabase
- App already synced (lastSync timestamp set)

**Steps:**
1. **Check current lastSync:**
   - Console logs: `[SyncService] Last sync was at: 1234567890`

2. **Make small change in Supabase:**
   - Update just 1 product

3. **Sync in app:**
   - Settings → Sync Now
   - Watch console logs

**Expected Result:**
- ✅ Logs show: `Fetched 1 products from Supabase` (not all 10+)
- ✅ Only modified record processed
- ✅ Other records skipped

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

### Test 10: Error Handling

**Objective:** Verify graceful handling of sync errors

#### Test 10A: Network Error
1. Turn off WiFi
2. Modify a product
3. Try to sync
4. Expected: Error message, data stays in queue (isDirty=true)
5. Turn on WiFi, sync again
6. Expected: Data syncs successfully

#### Test 10B: Invalid Data
1. In Supabase, create product with NULL name (violates NOT NULL)
2. Try to sync in app
3. Expected: Error logged, other records still sync

#### Test 10C: RPC Function Missing
1. In Supabase SQL editor, drop one RPC function:
   ```sql
   DROP FUNCTION fetch_products_since(BIGINT);
   ```
2. Try to sync
3. Expected: Error logged, graceful failure

**Expected Results:**
- ✅ No crashes
- ✅ Clear error messages in console
- ✅ Partial sync succeeds even if one entity fails

**Status:** [ ] Pass  [ ] Fail

**Notes:**
_____________________________________

---

## 📊 Test Summary

### Overall Results

| Test | Status | Notes |
|------|--------|-------|
| 1. Basic Push Sync | ☐ | |
| 2. Basic Pull Sync | ☐ | |
| 3. Update Sync | ☐ | |
| 4. Conflict Resolution | ☐ | |
| 5. Soft Delete Sync | ☐ | |
| 6. Customer Sync | ☐ | |
| 7. Invoice + Items Sync | ☐ | |
| 8. Multi-Device Sync | ☐ | |
| 9. Incremental Sync | ☐ | |
| 10. Error Handling | ☐ | |

**Total Passed:** _____ / 10

**Overall Status:** ☐ All Pass  ☐ Some Failures  ☐ Major Issues

---

## 🐛 Issues Found

### Issue 1
**Description:** 
**Severity:** ☐ Critical  ☐ Major  ☐ Minor
**Steps to Reproduce:**
**Expected:**
**Actual:**
**Fix:**

### Issue 2
**Description:**
**Severity:** ☐ Critical  ☐ Major  ☐ Minor
**Steps to Reproduce:**
**Expected:**
**Actual:**
**Fix:**

---

## 📝 Conclusion

**Date Completed:** ____________  
**Tester:** ____________  
**Overall Assessment:**

**Recommendations:**
- [ ] Ready for production
- [ ] Needs minor fixes
- [ ] Requires major work

**Next Steps:**


---

## 🔧 Debugging Tips

### Console Log Filters
Watch for these key log patterns:
```
[SyncService] Starting push sync...
[SyncService] Pushed product: ...
[SyncService] Starting pull sync...
[SyncService] Fetched N products from Supabase
[SyncService] Updated product: ... (remote newer)
[SyncService] Skipped product: ... (local newer)
[SyncService] Pull sync completed successfully
```

### SQL Queries for Verification

**Check all products:**
```sql
SELECT id, name, category, price, updated_at, deleted_at 
FROM products 
ORDER BY updated_at DESC;
```

**Check sync timestamps:**
```sql
SELECT name, updated_at FROM products WHERE name LIKE 'Test%';
```

**Check soft deletes:**
```sql
SELECT COUNT(*) FROM products WHERE deleted_at IS NOT NULL;
```

**Verify invoice relationships:**
```sql
SELECT i.invoice_number, COUNT(ii.id) as item_count, SUM(ii.quantity * ii.unit_price) as total
FROM invoices i
LEFT JOIN invoice_items ii ON i.id = ii.invoice_id
GROUP BY i.id, i.invoice_number;
```

---

**Last Updated:** October 20, 2025  
**Next Review:** After testing completion
