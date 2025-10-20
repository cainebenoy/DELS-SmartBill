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
    
    // Auto sign-in for development/testing to bypass RLS
    // TODO: Replace with proper Google OAuth in production
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        print('[SupabaseInit] No session found, signing in anonymously for testing...');
        await Supabase.instance.client.auth.signInAnonymously();
        print('[SupabaseInit] Anonymous sign-in successful');
      } else {
        print('[SupabaseInit] Existing session found');
      }
    } catch (e) {
      print('[SupabaseInit] Auto sign-in failed: $e');
      // Continue anyway - app will work offline
    }
  }
}
