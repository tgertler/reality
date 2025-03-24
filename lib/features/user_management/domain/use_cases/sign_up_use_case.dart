import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
import '../repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repository;
final Logger _logger = getLogger('SignUp');

  SignUp(this.repository);

  Future<void> call(String email, String password) async {
    _logger.i('Starting SignUp use case for email: $email');
    try {
      await repository.signUpWithEmailAndPassword(email, password);
      _logger.i('Successfully signed up user with email: $email');
    } catch (e, stackTrace) {
      _logger.e('Error during SignUp use case', e, stackTrace);
      rethrow;
    }
  }
}