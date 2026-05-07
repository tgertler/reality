import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repository;
final Logger _logger = getLogger('SignUp');

  SignUp(this.repository);

  Future<AuthResponse> call(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    _logger.i('Starting SignUp use case for email: $email');
    try {
      final response = await repository.signUpWithEmailAndPassword(
        email,
        password,
        data: data,
      );
      _logger.i('Successfully signed up user with email: $email');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Error during SignUp use case', e, stackTrace);
      rethrow;
    }
  }
}