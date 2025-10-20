import 'package:shared_preferences/shared_preferences.dart';
import '../data/db/app_database.dart';


class SyncService {
  static const _lastSyncKey = 'last_sync_at';

  Future<void> push(AppDatabase db) async {
    // Fetch dirty records
  // TODO: Fetch dirty records and upsert to Supabase
    // TODO: Filter for isDirty only
    // TODO: Upsert to Supabase
    // TODO: Clear isDirty after successful sync
  }

  Future<void> pull(AppDatabase db) async {
  // TODO: Use SharedPreferences for lastSync in Supabase pull
  // TODO: Use lastSync for Supabase pull
    // TODO: Fetch changes from Supabase since lastSync
    // TODO: Merge changes to local DB
    // TODO: Update lastSync
  }

  Future<void> updateLastSync(int millis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, millis);
  }

  Future<int> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSyncKey) ?? 0;
  }
}
