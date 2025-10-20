import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  // Try to get from .env file first, fallback to --dart-define
  static String get supabaseUrl {
    final envValue = dotenv.env['SUPABASE_URL'];
    if (envValue != null && envValue.isNotEmpty) return envValue;
    return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  }

  static String get supabaseAnonKey {
    final envValue = dotenv.env['SUPABASE_ANON_KEY'];
    if (envValue != null && envValue.isNotEmpty) return envValue;
    return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  }
}
