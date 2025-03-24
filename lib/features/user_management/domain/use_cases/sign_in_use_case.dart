import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repository;
final Logger _logger = getLogger('AuthRepository');
  SignIn(this.repository);

  Future<void> call(String email, String password) async {
    _logger.i('Starting SignIn use case for email: $email');
    try {
      await repository.signInWithEmailAndPassword(email, password);
      _logger.i('Successfully signed in user with email: $email');
    } catch (e, stackTrace) {
      _logger.e('Error during SignIn use case', e, stackTrace);
      rethrow;
    }
  }
}