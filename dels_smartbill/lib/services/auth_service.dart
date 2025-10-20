import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;
  final Logger _logger = Logger();

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.dels.smartbill://oauth-callback',
      );
      _logger.i('[AuthService] Google sign-in initiated');
    } catch (e) {
      _logger.e('[AuthService] Google sign-in failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _logger.i('[AuthService] Signed out');
    } catch (e) {
      _logger.e('[AuthService] Sign-out failed: $e');
      rethrow;
    }
  }

  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  String? get userId => currentUser?.id;

  String? get userEmail => currentUser?.email;
}
