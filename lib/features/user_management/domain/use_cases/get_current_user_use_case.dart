import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
import '../repositories/auth_repository.dart';
import '../entities/user.dart';

class GetCurrentUser {
  final AuthRepository repository;
  final Logger _logger = getLogger('GetCurrentUser');

  GetCurrentUser(this.repository);

  Future<User?> call() async {
    _logger.i('Starting GetCurrentUser use case');
    try {
      final user = await repository.getCurrentUser();
      if (user != null) {
        _logger.i('Successfully fetched current user: $user');
        return User(id: user.id, email: user.email ?? '');
      }
      _logger.w('No current user found');
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error during GetCurrentUser use case', e, stackTrace);
      rethrow;
    }
  }
}