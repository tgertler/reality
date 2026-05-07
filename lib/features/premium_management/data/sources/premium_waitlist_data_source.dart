import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';

class PremiumWaitlistDataSource {
  final SupabaseClient supabaseClient;
  final Logger _logger = getLogger('PremiumWaitlistDataSource');

  PremiumWaitlistDataSource(this.supabaseClient);

  Future<void> joinWaitlist(String userId) async {
    _logger.i('Joining premium waitlist: userId=$userId');
    await supabaseClient.from('premium_waitlist').insert({
      'user_id': userId,
    });
    _logger.i('Joined waitlist successfully');
  }

  Future<bool> isOnWaitlist(String userId) async {
    _logger.i('Checking waitlist status: userId=$userId');
    final response = await supabaseClient
        .from('premium_waitlist')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    final results = response as List<dynamic>;
    final onList = results.isNotEmpty;
    _logger.i('Waitlist status: $onList');
    return onList;
  }
}
