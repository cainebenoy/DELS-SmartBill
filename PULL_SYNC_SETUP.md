# Pull Sync Setup Guide

This guide explains how to set up the RPC functions needed for pull synchronization.

## Overview

The pull sync feature allows the app to fetch changes from Supabase that were made on other devices or directly in the database. This completes the bidirectional synchronization.

## Setup Steps

### Step 1: Run the RPC Functions SQL

1. Open your Supabase project: https://supabase.com/dashboard/project/wppagoydvelahftjkgpx
2. Click on **SQL Editor** in the left sidebar
3. Open the file `supabase/fetch_changes_rpc.sql` from this project
4. Copy all the SQL code
5. Paste it into the SQL Editor
6. Click **Run** or press `Ctrl+Enter`

### Step 2: Verify the Functions

Run this query to verify the functions were created:

```sql
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE 'fetch_%_since'
ORDER BY routine_name;
```

You should see 4 functions:
- `fetch_customers_since`
- `fetch_invoice_items_since`
- `fetch_invoices_since`
- `fetch_products_since`

### Step 3: Test the Functions

Test each function to ensure it works:

```sql
-- Fetch all products (use 0 to get everything)
SELECT * FROM fetch_products_since(0);

-- Fetch all customers
SELECT * FROM fetch_customers_since(0);

-- Fetch all invoices
SELECT * FROM fetch_invoices_since(0);

-- Fetch all invoice items
SELECT * FROM fetch_invoice_items_since(0);
```

### Step 4: Test in the App

1. Open the app
2. Go to **Settings** page
3. Click **Sync Now** button
4. You should see:
   - "Pushing local changes..."
   - "Pulling remote changes..."
   - "Sync successful! ✓"

## How It Works

### RPC Functions

Each RPC function:
- Accepts a timestamp in milliseconds (from Dart's `DateTime.millisecondsSinceEpoch`)
- Converts it to PostgreSQL timestamp for comparison
- Returns all records where `updated_at > timestamp`
- Orders results by `updated_at ASC` for chronological processing
- Uses `SECURITY DEFINER` to bypass RLS (functions have explicit GRANT permissions)

### Pull Sync Process

1. **Get Last Sync Time**: Retrieve the last sync timestamp from SharedPreferences
2. **Call RPC Functions**: For each entity type, call the corresponding RPC function
3. **Conflict Resolution**: For each remote record:
   - Check if it exists locally
   - Compare `updated_at` timestamps
   - If remote is newer, update local record
   - If local is newer, skip (keep local changes)
4. **Update Last Sync**: Store the current timestamp for next sync

### Timestamp Format

- Dart stores: `DateTime.now().millisecondsSinceEpoch` (e.g., `1704067200000`)
- PostgreSQL expects: `timestamp with time zone`
- Conversion: `to_timestamp(millis / 1000.0)`

## Testing Multi-Device Sync

### Scenario 1: Create on Device A, Sync to Device B

1. **Device A**: Create a new product "Test Product"
2. **Device A**: Click "Sync Now" → Product pushed to Supabase
3. **Device B**: Click "Sync Now" → Product pulled from Supabase
4. **Device B**: Verify "Test Product" appears in products list

### Scenario 2: Modify in Supabase, Pull to App

1. **Supabase Dashboard**: Go to Table Editor → products
2. Click on a product row and edit the name
3. **App**: Click "Sync Now"
4. **App**: Verify the product name updated to match Supabase

### Scenario 3: Conflict Resolution

1. **Device A**: Edit product "Widget" → Change price to $10.00
2. **Device B**: Edit same product "Widget" → Change price to $15.00
3. **Device A**: Sync first (pushes $10.00)
4. **Device B**: Sync second (pushes $15.00, which is newer)
5. **Device A**: Sync again (pulls $15.00, Device B wins)

Result: Last-write-wins conflict resolution - Device B's change ($15.00) is kept

## Troubleshooting

### Error: "function fetch_products_since does not exist"

**Cause**: RPC functions not created in Supabase

**Solution**: Re-run the SQL from `supabase/fetch_changes_rpc.sql`

### Error: "permission denied for function"

**Cause**: GRANT statements didn't execute properly

**Solution**: Run these GRANT statements individually:

```sql
GRANT EXECUTE ON FUNCTION fetch_products_since(BIGINT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION fetch_customers_since(BIGINT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION fetch_invoices_since(BIGINT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION fetch_invoice_items_since(BIGINT) TO authenticated, anon;
```

### Sync pulls nothing even with remote changes

**Cause**: `lastSync` timestamp might be in the future

**Solution**: Clear app data to reset last sync timestamp, or manually set it:

```dart
// In settings page or dev tools
await SyncService().updateLastSync(0); // Reset to fetch everything
```

### Duplicate records after sync

**Cause**: Entity lookup by ID failed, inserted duplicate

**Solution**: 
- Check that primary key constraints exist in both Floor and Supabase
- Verify entity IDs are proper UUIDs (not Flutter's UniqueKey format)
- Clear local database and re-sync from scratch

## Console Output

During a successful pull sync, you should see:

```
[SyncService] Starting pull sync...
[SyncService] Last sync was at: 1704067200000 (2024-01-01 00:00:00.000)
[SyncService] Pulling products since 1704067200000...
[SyncService] Fetched 3 products from Supabase
[SyncService] Inserted new product: Widget A
[SyncService] Updated product: Widget B (remote newer)
[SyncService] Skipped product: Widget C (local newer)
[SyncService] Pulling customers since 1704067200000...
[SyncService] Fetched 2 customers from Supabase
...
[SyncService] Pull sync completed successfully
```

## Architecture Notes

### Why RPC Functions?

We use RPC functions instead of direct Supabase queries because:
1. **Timestamp Conversion**: Clean conversion from milliseconds to PostgreSQL timestamp
2. **Security**: SECURITY DEFINER allows bypassing RLS while maintaining explicit GRANT control
3. **Performance**: Server-side filtering more efficient than fetching all and filtering locally
4. **Flexibility**: Easy to modify query logic (add filters, joins, etc.) without app updates

### Conflict Resolution Strategy

Currently using **Last-Write-Wins**:
- Compare `updated_at` timestamps
- Most recent change overwrites older change
- Simple but may lose data in rare edge cases

Future improvements could include:
- **Field-level merging**: Merge non-conflicting field changes
- **Conflict detection UI**: Prompt user to choose when conflicts detected
- **Operational transformation**: Apply both changes if semantically compatible

### Soft Deletes

Deleted records have `deleted_at` timestamp set:
- Pull sync receives deleted records and marks them `isDeleted = true` locally
- Records stay in database but filtered out of queries
- Allows restoration and maintains referential integrity

## Next Steps

After pull sync is working:

1. **Task 5**: Wire sync everywhere - Call push/pull after all mutations
2. **Task 6**: Background sync - Use workmanager to sync periodically
3. **Task 7**: Real authentication - Replace anonymous auth with Google OAuth
4. **Task 8**: Conflict UI - Add user-visible conflict resolution for important changes

## Related Files

- `lib/services/sync_service.dart` - Pull sync implementation
- `supabase/fetch_changes_rpc.sql` - RPC function definitions
- `lib/features/settings/settings_page.dart` - Sync button UI
- `SYNC_IMPLEMENTATION.md` - Technical documentation
- `ANONYMOUS_AUTH_SETUP.md` - Authentication setup
