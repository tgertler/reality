import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository repository;
final Logger _logger = getLogger('SignOut');

  SignOut(this.repository);

  Future<void> call() async {
    _logger.i('Starting SignOut use case');
    try {
      await repository.signOut();
      _logger.i('Successfully signed out user');
    } catch (e, stackTrace) {
      _logger.e('Error during SignOut use case', e, stackTrace);
      rethrow;
    }
  }
}