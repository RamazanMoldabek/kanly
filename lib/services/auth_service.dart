import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign Up with Email, Password & Full Name
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {'full_name': fullName.trim()},
    );
    notifyListeners();
    return response;
  }

  /// Sign In with Email & Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    notifyListeners();
    return response;
  }

  /// Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }
}
