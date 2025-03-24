import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final supabaseClient = Supabase.instance.client;
  final Logger _logger = getLogger('AuthRepositoryImpl');

  @override
  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    _logger.i('Starting signInWithEmailAndPassword for email: $email');
    try {
      final response = await supabaseClient.auth.signInWithPassword(password: password, email: email);
      _logger.i('Successfully signed in user: ${response.user}');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Error during signInWithEmailAndPassword', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password) async {
    _logger.i('Starting signUpWithEmailAndPassword for email: $email');
    try {
      final response = await supabaseClient.auth.signUp(email: email, password: password);
      _logger.i('Successfully signed up user: ${response.user}');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Error during signUpWithEmailAndPassword', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _logger.i('Starting signOut');
    try {
      await supabaseClient.auth.signOut();
      _logger.i('Successfully signed out user');
    } catch (e, stackTrace) {
      _logger.e('Error during signOut', e, stackTrace);
      rethrow;
    }
  }

  @override
  String? getCurrentUserEmail() {
    _logger.i('Getting current user email');
    final session = supabaseClient.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  @override
  Future<User?> getCurrentUser() async {
    _logger.i('Getting current user');
    final User? user = supabaseClient.auth.currentSession?.user;
    return user;
  }
}