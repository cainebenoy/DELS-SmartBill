import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_env.dart';

class SupabaseInit {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (AppEnv.supabaseUrl.isEmpty || AppEnv.supabaseAnonKey.isEmpty) {
      // Leave uninitialized in dev if keys are not provided; caller can ignore.
      return;
    }
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      debug: false,
    );
    _initialized = true;
  }
}
