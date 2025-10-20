import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_env.dart';
import 'package:logger/logger.dart';

class SupabaseInit {
  static final Logger _logger = Logger();
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
        _logger.i('[SupabaseInit] No session found, signing in anonymously for testing...');
        await Supabase.instance.client.auth.signInAnonymously();
        _logger.i('[SupabaseInit] Anonymous sign-in successful');
      } else {
        _logger.i('[SupabaseInit] Existing session found');
      }
    } catch (e) {
      _logger.e('[SupabaseInit] Auto sign-in failed: $e');
      // Continue anyway - app will work offline
    }
  }
}
