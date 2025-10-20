# Sync Implementation Guide

**Date:** October 20, 2025  
**Status:** Push Logic ✅ Complete | Pull Logic ⏳ Pending

---

## 🎯 Overview

This document describes the implementation of the Supabase synchronization system for DELS SmartBill. The sync system enables offline-first operation with bidirectional data synchronization between local Floor database and Supabase cloud database.

---

## ✅ Completed: Push Sync Logic

### Implementation Summary

The `push()` method in `SyncService` now:
1. ✅ Fetches all dirty records (isDirty=true) from local database
2. ✅ Maps local entities to Supabase format
3. ✅ Upserts data to Supabase tables
4. ✅ Handles soft deletes (isDeleted=true)
5. ✅ Clears isDirty flag after successful sync
6. ✅ Includes comprehensive error handling and logging
7. ✅ Continues syncing other records if one fails

### Architecture

```
┌─────────────────┐
│  UI Layer       │
│  (Products,     │
│   Invoices,     │
│   etc.)         │
└────────┬────────┘
         │ Creates/Updates/Deletes
         │ (marks isDirty=true)
         v
┌─────────────────┐
│  Floor DB       │
│  (SQLite)       │
│                 │
│  - Products     │
│  - Customers    │
│  - Invoices     │
│  - InvoiceItems │
└────────┬────────┘
         │
         │ findDirty()
         v
┌─────────────────┐
│  SyncService    │
│  .push()        │
│                 │
│  - Fetch dirty  │
│  - Map to JSON  │
│  - Upsert       │
│  - Clear dirty  │
└────────┬────────┘
         │
         │ Supabase Client
         v
┌─────────────────┐
│  Supabase       │
│  (PostgreSQL)   │
│                 │
│  - products     │
│  - customers    │
│  - invoices     │
│  - invoice_items│
└─────────────────┘
```

### New DAO Methods Added

Added `findDirty()` method to all DAOs to fetch records that need syncing:

**ProductDao:**
```dart
@Query('SELECT * FROM ProductEntity WHERE isDirty = 1')
Future<List<ProductEntity>> findDirty();
```

**CustomerDao:**
```dart
@Query('SELECT * FROM CustomerEntity WHERE isDirty = 1')
Future<List<CustomerEntity>> findDirty();
```

**InvoiceDao:**
```dart
@Query('SELECT * FROM InvoiceEntity WHERE isDirty = 1')
Future<List<InvoiceEntity>> findDirty();
```

**InvoiceItemDao:**
```dart
@Query('SELECT * FROM InvoiceItemEntity WHERE isDirty = 1')
Future<List<InvoiceItemEntity>> findDirty();
```

### Sync Flow Details

#### 1. Products Sync
```dart
Future<void> _pushProducts(AppDatabase db, SupabaseClient supabase) async {
  final dirtyProducts = await db.productDao.findDirty();
  
  for (final product in dirtyProducts) {
    if (product.isDeleted) {
      // Soft delete: Update deleted_at timestamp
      await supabase.from('products').update({
        'deleted_at': DateTime...toIso8601String(),
        'updated_at': product.updatedAt.toIso8601String(),
      }).eq('id', product.id);
    } else {
      // Upsert: Insert or update
      await supabase.from('products').upsert({
        'id': product.id,
        'name': product.name,
        'category': product.category,
        'price': product.price,
        'created_at': product.createdAt.toIso8601String(),
        'updated_at': product.updatedAt.toIso8601String(),
        'deleted_at': null,
      });
    }
    
    // Clear isDirty flag locally
    await db.productDao.updateOne(product.copyWith(isDirty: false));
  }
}
```

#### 2. Customers Sync
- Same pattern as products
- Maps: id, name, created_at, updated_at, deleted_at
- Note: phone, email, address fields exist locally but Supabase schema only has name (can extend later)

#### 3. Invoices Sync
- Maps: id, invoice_number, customer_id, total_amount, created_by_user_id, timestamps
- **Special handling:** Server can reassign invoice_number via trigger
- Response is captured to detect server-side changes

#### 4. Invoice Items Sync
- Maps: id, invoice_id, product_id, quantity, unit_price, timestamps
- Links to parent invoice via foreign key

### Error Handling

The implementation includes multiple layers of error handling:

1. **Service Level:**
   ```dart
   try {
     await _pushProducts(db, supabase);
     await _pushCustomers(db, supabase);
     // etc...
   } catch (e, stackTrace) {
     print('[SyncService] Push sync failed: $e');
     rethrow; // Let caller handle
   }
   ```

2. **Entity Level:**
   ```dart
   for (final product in dirtyProducts) {
     try {
       await supabase.from('products').upsert(...);
     } catch (e) {
       print('[SyncService] Failed to push product: $e');
       // Continue with next product (don't fail entire sync)
     }
   }
   ```

3. **Initialization Check:**
   ```dart
   SupabaseClient? supabase;
   try {
     supabase = Supabase.instance.client;
   } catch (e) {
     print('[SyncService] Supabase not initialized, skipping push');
     return; // Graceful degradation
   }
   ```

### Logging

Console logs track sync progress:
- `[SyncService] Starting push sync...`
- `[SyncService] Pushing N products...`
- `[SyncService] Pushed product: Product Name`
- `[SyncService] No dirty products to push`
- `[SyncService] Push sync completed successfully`
- `[SyncService] Failed to push product X: error`

### Testing the Push Sync

#### Manual Test via Settings Page

1. Open the app
2. Go to Settings tab
3. Create/modify some products
4. Click "Sync Now" button
5. Check console logs for sync progress
6. Verify in Supabase dashboard that data appears

#### Test from Terminal

```powershell
# Run app with Supabase credentials
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://wppagoydvelahftjkgpx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...

# Watch console for sync logs
```

#### Verify in Supabase

```sql
-- Check products table
SELECT id, name, category, price, created_at, updated_at 
FROM products 
WHERE deleted_at IS NULL
ORDER BY updated_at DESC;

-- Check sync worked
SELECT COUNT(*) FROM products WHERE deleted_at IS NULL;
```

---

## ⏳ Pending: Pull Sync Logic

### Requirements

The `pull()` method needs to:
1. ⏳ Get last sync timestamp from SharedPreferences
2. ⏳ Call Supabase RPC functions (fetch_products_since, etc.)
3. ⏳ Map remote data to local entities
4. ⏳ Merge into Floor database
5. ⏳ Handle conflicts (last-write-wins strategy)
6. ⏳ Update lastSync timestamp

### Planned Implementation

```dart
Future<void> pull(AppDatabase db) async {
  try {
    final supabase = Supabase.instance.client;
    final lastSync = await getLastSync();
    final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSync);
    
    print('[SyncService] Starting pull sync from $lastSyncDate...');
    
    // 1. Fetch products
    final productsData = await supabase
        .rpc('fetch_products_since', params: {'since': lastSyncDate.toIso8601String()})
        .select();
    
    // 2. Map and merge
    for (final data in productsData) {
      final product = _mapToProductEntity(data);
      
      // Conflict resolution: Check if local copy is newer
      final existing = await db.productDao.findById(product.id);
      if (existing != null && existing.updatedAt.isAfter(product.updatedAt)) {
        print('[SyncService] Skipping ${product.name}: local is newer');
        continue;
      }
      
      // Merge
      await db.productDao.updateOne(product.copyWith(isDirty: false));
    }
    
    // Repeat for customers, invoices, invoice_items...
    
    // 3. Update lastSync
    await updateLastSync(DateTime.now().millisecondsSinceEpoch);
    
    print('[SyncService] Pull sync completed successfully');
  } catch (e) {
    print('[SyncService] Pull sync failed: $e');
    rethrow;
  }
}
```

### Supabase RPC Functions (Already Created)

The schema includes these helper functions:

```sql
-- Fetch products changed since timestamp
CREATE FUNCTION fetch_products_since(since timestamptz)
RETURNS SETOF products AS $$
  SELECT * FROM products 
  WHERE updated_at > since 
     OR (deleted_at IS NOT NULL AND deleted_at > since);
$$ LANGUAGE sql STABLE;

-- Similar functions for:
-- - fetch_customers_since
-- - fetch_invoices_since  
-- - fetch_invoice_items_since
```

### Conflict Resolution Strategy

**Last-Write-Wins:**
1. Compare `updated_at` timestamps
2. If remote is newer → accept remote changes
3. If local is newer → skip merge (keep local)
4. If equal → no conflict (same data)

**Future Enhancement:**
- Per-field merging for complex conflicts
- User-prompted resolution for critical data
- Conflict log table for audit trail

---

## 🔧 Configuration

### Environment Variables

Required in `.env` or `--dart-define`:
```properties
SUPABASE_URL=https://wppagoydvelahftjkgpx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
```

### Supabase Setup

1. **Tables:** products, customers, invoices, invoice_items
2. **RLS Policies:** Allow all for authenticated users
3. **Triggers:** Auto-update timestamps, assign invoice numbers
4. **RPC Functions:** fetch_*_since for incremental sync
5. **Indices:** On updated_at, deleted_at for efficient queries

---

## 📊 Performance Considerations

### Current Implementation

- ✅ Syncs only dirty records (not full table scan)
- ✅ Individual record error handling (one failure doesn't block others)
- ✅ Logging for debugging and monitoring
- ⚠️ Sequential processing (can be slow for many records)

### Future Optimizations

1. **Batch Upserts:**
   ```dart
   await supabase.from('products').upsert(batchOfProducts);
   ```

2. **Parallel Sync:**
   ```dart
   await Future.wait([
     _pushProducts(db, supabase),
     _pushCustomers(db, supabase),
     _pushInvoices(db, supabase),
   ]);
   ```

3. **Delta Sync:**
   - Only sync changed fields (requires field-level tracking)

4. **Compression:**
   - For large payloads, compress JSON before upload

---

## 🐛 Known Issues & Limitations

### Current Limitations

1. **No offline queue:** If sync fails, user must retry manually
2. **No conflict UI:** Silent last-write-wins (could lose data)
3. **No partial sync recovery:** If sync crashes midway, no resume
4. **Print statements:** Need proper logging framework
5. **No metrics:** Can't track sync performance or failures

### Planned Improvements

- [ ] Add retry queue with exponential backoff
- [ ] Track sync metrics (duration, record count, failures)
- [ ] Add conflict resolution UI
- [ ] Implement sync progress indicator
- [ ] Add sync health dashboard in Settings

---

## 🧪 Testing Checklist

### Unit Tests (To Be Written)

- [ ] Test `findDirty()` returns only isDirty=true records
- [ ] Test `push()` with empty dirty list (no-op)
- [ ] Test `push()` with mix of new/updated/deleted records
- [ ] Test error handling when Supabase is unreachable
- [ ] Test isDirty flag is cleared after successful sync
- [ ] Mock Supabase client for isolated testing

### Integration Tests (To Be Written)

- [ ] Create product locally → sync → verify in Supabase
- [ ] Soft delete product → sync → verify deleted_at set
- [ ] Modify product offline → sync → verify update
- [ ] Create invoice with items → sync → verify relationships
- [ ] Sync with network error → verify graceful failure

### Manual Test Scenarios

✅ **Completed:**
- Create products and verify sync logs

⏳ **Pending:**
- Test with 100+ dirty records (performance)
- Test with network interruption mid-sync
- Test sync after app restart
- Test concurrent sync requests
- Verify Supabase data matches local DB

---

## 📝 Next Steps

### Immediate (Sprint 1)

1. ✅ Implement push sync logic
2. ⏳ Implement pull sync logic
3. ⏳ Wire sync to all mutation points (Products CRUD, Invoice creation)
4. ⏳ Add connectivity check before sync
5. ⏳ Update Settings page with sync status

### Near-term (Sprint 2)

- Add background sync with Workmanager
- Implement sync on app resume
- Add sync conflict resolution
- Replace print with proper logging

### Long-term

- Add sync metrics and monitoring
- Implement partial sync recovery
- Add sync health dashboard
- Performance optimization (batching, parallel)

---

## 🔗 Related Files

- `lib/services/sync_service.dart` - Main sync implementation
- `lib/data/db/daos/*.dart` - DAO layer with findDirty() methods
- `lib/features/settings/settings_page.dart` - Manual sync trigger
- `supabase/schema.sql` - Database schema with RPC functions
- `.env` - Supabase credentials

---

**Last Updated:** October 20, 2025  
**Next Review:** After pull sync implementation
