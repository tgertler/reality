import 'package:frontend/core/utils/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabaseClient = Supabase.instance.client;

  //Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(
      String email, String password) async {
    return await supabaseClient.auth
        .signInWithPassword(password: password, email: email);
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword(
      String email, String password) async {
    return await supabaseClient.auth.signUp(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  //Get user email
  String? getCurrentUserEmail() {
    final session = supabaseClient.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
