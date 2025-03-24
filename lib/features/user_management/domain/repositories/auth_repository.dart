import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<AuthResponse> signInWithEmailAndPassword(String email, String password);
  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  String? getCurrentUserEmail();
  Future<User?> getCurrentUser();
}