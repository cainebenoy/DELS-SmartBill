# DELS SmartBill Sync Issue: Detailed Explanation

## Problem Summary

**Symptom:**  
When you add or edit a product directly in Supabase, it does NOT appear in your app after clicking "Sync Now"—unless you first create a product locally in the app. Only then do the Supabase changes show up.

---

## Why This Happens

### 1. The Role of `lastSync`

Your sync logic uses a `lastSync` timestamp (stored in SharedPreferences) to fetch only records from Supabase that have changed since the last sync.  
- On every pull, you fetch products with `updated_at > lastSync`.
- After pulling, you update `lastSync` to the current time.

**Key code:**
```dart
final lastSync = await getLastSync();
// ... fetch from Supabase where updated_at > lastSync ...
await updateLastSync(DateTime.now().millisecondsSinceEpoch);
```

### 2. The Initial Sync Trap

- On first app run, `lastSync` is 0, so you fetch all products.
- After that, `lastSync` is set to the time of the last pull.
- If you add/edit a product in Supabase **after** the last sync, but its `updated_at` is not newer than `lastSync`, it will NOT be fetched.

### 3. Supabase `updated_at` Issues

- Your Supabase tables have a trigger to update `updated_at` on every UPDATE.
- But if you add a product in the Supabase UI, or edit it without actually triggering an UPDATE (or if the trigger is missing/misconfigured), the `updated_at` may not be set to the current time.
- If the `updated_at` is older than `lastSync`, your app will skip it.

**Supabase trigger code:**
```sql
create or replace function set_timestamp()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_timestamp_products
before update on products
for each row execute procedure set_timestamp();
```

### 4. The Local Change "Workaround"

When you create a product locally:
- The app pushes it to Supabase, then pulls again.
- This resets `lastSync` and may cause the app to fetch all products, including those you added in Supabase.
- This is why Supabase changes only appear after a local change.

---

## How the Code Connects

### Pull Sync Logic (`sync_service.dart`)

```dart
Future<void> pull(AppDatabase db) async {
  // ...existing code...
  final lastSync = await getLastSync();
  // Fetch changes from Supabase
  await _pullProducts(db, supabase, lastSync);
  // ...other entities...
  await updateLastSync(DateTime.now().millisecondsSinceEpoch);
}
```

### Fetching from Supabase

```dart
final response = await supabase.rpc('fetch_products_since', 
  params: {'since_timestamp': lastSync}
) as List<dynamic>;
```

### Filtering in Supabase

```sql
create or replace function fetch_products_since(since timestamptz)
returns setof products as $$
  select * from products where updated_at > since or (deleted_at is not null and deleted_at > since);
$$ language sql stable;
```

### Local DB Filtering

Your DAO only returns products where `isDeleted = 0`:
```dart
@Query('SELECT * FROM ProductEntity WHERE isDeleted = 0 AND (name LIKE :q OR category LIKE :q) ORDER BY name ASC')
Future<List<ProductEntity>> search(String q);
```

---

## How to Investigate

1. **Check the `updated_at` value** of the product in Supabase after you add/edit it.  
   - Is it newer than the last sync time in your app logs?
   - If not, the trigger may not be firing, or you may be editing in a way that doesn’t trigger an UPDATE.

2. **Check your app logs** for lines like:
   ```
   [SyncService] Last sync was at: 1760964830378 (2025-10-20 18:23:50.378)
   [SyncService] Pulling products since 1760964830378...
   [SyncService] Fetched X products from Supabase
   ```
   - If "Fetched 0 products", it means nothing in Supabase has `updated_at > lastSync`.

3. **Test the trigger:**
   - In Supabase SQL editor, run:
     ```sql
     update products set name = 'Test' where id = 'your-product-id';
     ```
   - Check if `updated_at` changes.

4. **Reset lastSync** in your app (using a debug button or by clearing SharedPreferences) and sync again.  
   - If all products appear, the issue is with the timestamp logic.

---

## How to Fix

### 1. Ensure Supabase Triggers Are Working

- Make sure your `set_timestamp` trigger is attached to the `products` table.
- Always use UPDATE statements to change products, not just direct cell edits in the UI.

### 2. Reset `lastSync` When Needed

- Add a debug button in your app to set `lastSync` to 0:
  ```dart
  await SyncService().updateLastSync(0);
  ```
- Then click "Sync Now" to force a full pull.

### 3. Educate Your Team

- When adding/editing data in Supabase, always ensure `updated_at` is updated.
- If you must manually add data, update the `updated_at` field to the current timestamp.

---

## TL;DR

- Your app only pulls products with `updated_at > lastSync`.
- If you add/edit products in Supabase and `updated_at` is not updated, the app will never fetch them.
- Fix: Ensure Supabase triggers are working, and reset `lastSync` to 0 if you want to force a full sync.

---

If you want to debug further, check:
- The value of `lastSync` in your app logs.
- The `updated_at` value in Supabase for your products.
- That your Supabase triggers are firing on every update.

Let me know if you want a step-by-step for any of these!
