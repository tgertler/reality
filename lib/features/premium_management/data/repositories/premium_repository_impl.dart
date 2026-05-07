import 'package:logger/logger.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/premium_repository.dart';
import '../sources/premium_waitlist_data_source.dart';

class PremiumRepositoryImpl implements PremiumRepository {
  final PremiumWaitlistDataSource dataSource;
  final Logger _logger = getLogger('PremiumRepositoryImpl');

  PremiumRepositoryImpl(this.dataSource);

  @override
  Future<void> joinWaitlist(String userId) async {
    _logger.i('joinWaitlist: userId=$userId');
    try {
      await dataSource.joinWaitlist(userId);
    } catch (e, st) {
      _logger.e('Error joining waitlist', e, st);
      rethrow;
    }
  }

  @override
  Future<bool> isOnWaitlist(String userId) async {
    _logger.i('isOnWaitlist: userId=$userId');
    try {
      return await dataSource.isOnWaitlist(userId);
    } catch (e, st) {
      _logger.e('Error checking waitlist', e, st);
      rethrow;
    }
  }
}
