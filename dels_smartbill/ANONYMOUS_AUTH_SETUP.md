# Enabling Anonymous Authentication for DELS SmartBill

**Date:** October 20, 2025  
**Purpose:** Allow sync functionality to work during development without requiring Google OAuth setup

---

## 🚨 Issue Encountered

**Error:** `PostgrestException: new row violates row-level security policy for table "products"`

**Cause:** Supabase RLS policies require authenticated users, but we're syncing with just the anon key.

---

## ✅ Solution: Anonymous Authentication

We've implemented automatic anonymous sign-in for development/testing. This satisfies RLS policies without requiring full OAuth setup.

### Changes Made

#### 1. Updated `supabase_client.dart`

Added automatic anonymous sign-in when no session exists:

```dart
// Auto sign-in for development/testing to bypass RLS
try {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    await Supabase.instance.client.auth.signInAnonymously();
  }
} catch (e) {
  // Continue anyway - app will work offline
}
```

#### 2. Updated RLS Policies

Created SQL migration to allow anonymous users: `supabase/enable_anonymous_auth.sql`

---

## 📝 Steps to Complete Setup

### Step 1: Enable Anonymous Auth in Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/wppagoydvelahftjkgpx/auth/providers
2. Scroll to **Anonymous Sign-ins**
3. Click **Enable** toggle
4. Click **Save**

### Step 2: Update RLS Policies

1. Go to: https://supabase.com/dashboard/project/wppagoydvelahftjkgpx/sql/new
2. Copy and paste the contents of `supabase/enable_anonymous_auth.sql`
3. Click **Run** button
4. Verify success message

### Step 3: Test Sync

1. Hot reload or restart the Flutter app
2. Check console - should see:
   ```
   [SupabaseInit] No session found, signing in anonymously for testing...
   [SupabaseInit] Anonymous sign-in successful
   ```
3. Create a new product (e.g., "Apple Juice", category "Beverages", price ₹50)
4. Go to Settings tab
5. Click **Sync Now** button
6. Should see successful sync in console:
   ```
   [SyncService] Starting push sync...
   [SyncService] Pushing 1 products...
   [SyncService] Pushed product: Apple Juice
   [SyncService] Push sync completed successfully
   ```

### Step 4: Verify in Supabase

1. Go to: https://supabase.com/dashboard/project/wppagoydvelahftjkgpx/editor
2. Click **products** table
3. You should see your synced product! 🎉

---

## 🔒 Security Notes

### Development/Testing Mode

- ✅ Anonymous auth allows anyone with the anon key to access data
- ✅ Perfect for development and testing
- ⚠️ Not suitable for production with sensitive data

### Production Recommendations

Before going to production, implement proper authentication:

1. **Enable Google OAuth** (Task #7 in roadmap)
   - Configure OAuth in Supabase
   - Implement sign-in flow in `AuthGate`
   - Store user sessions
   - Enable `ENABLE_AUTH` flag

2. **Update RLS Policies** to require authenticated users:
   ```sql
   -- For production
   CREATE POLICY "Authenticated only" ON products 
     FOR ALL 
     USING (auth.role() = 'authenticated') 
     WITH CHECK (auth.role() = 'authenticated');
   ```

3. **Optional:** Add email domain restriction
   - Limit sign-ins to `@dels.com` domain only
   - Configure in Supabase Auth settings

---

## 🧪 Testing Checklist

After completing setup steps:

- [ ] Anonymous auth enabled in Supabase dashboard
- [ ] RLS policies updated (ran SQL migration)
- [ ] App shows anonymous sign-in success in console
- [ ] Can create products in app
- [ ] Products sync to Supabase without errors
- [ ] Products visible in Supabase table editor
- [ ] Can create customers and invoices
- [ ] All entities sync successfully

---

## 🔄 Current vs Future State

### Current (Development)

```
App Start
   ↓
SupabaseInit.ensureInitialized()
   ↓
No session found?
   ↓ YES
signInAnonymously()
   ↓
Anonymous session created
   ↓
Sync works! ✅
```

### Future (Production)

```
App Start
   ↓
SupabaseInit.ensureInitialized()
   ↓
AuthGate checks session
   ↓
No session found?
   ↓ YES
Show Sign In Screen
   ↓
User clicks "Sign in with Google"
   ↓
Google OAuth flow
   ↓
Authenticated session created
   ↓
User sees app
   ↓
Sync works with user context! ✅
(Invoice created_by_user_id populated)
```

---

## 📚 Related Files

- `lib/core/supabase/supabase_client.dart` - Anonymous auth implementation
- `supabase/enable_anonymous_auth.sql` - RLS policy migration
- `supabase/schema.sql` - Original schema (needs update for production)
- `lib/features/auth/auth_gate.dart` - Future Google OAuth implementation

---

## 🐛 Troubleshooting

### Issue: Still getting RLS policy error

**Solution:**
1. Verify anonymous auth is enabled in Supabase dashboard
2. Verify RLS policies were updated (check in SQL editor)
3. Restart the app to trigger fresh sign-in

### Issue: "signInAnonymously() not supported"

**Solution:**
- Supabase anonymous auth might not be enabled
- Follow Step 1 above to enable in dashboard

### Issue: Sync works but no user_id in invoices

**Expected:**
- Anonymous users have a temporary user ID
- When implementing Google OAuth, replace `createdByUserId: 'local'` with actual user ID

---

## ✅ Next Steps After This Works

Once sync is working with anonymous auth:

1. ✅ Complete Task 2: Implement Pull Sync Logic
2. ✅ Complete Task 5: Wire Sync Everywhere
3. ✅ Later: Complete Task 7: Google Authentication (replace anonymous auth)

---

**Last Updated:** October 20, 2025  
**Status:** Waiting for Supabase dashboard configuration
