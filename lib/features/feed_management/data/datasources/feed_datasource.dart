import 'package:supabase_flutter/supabase_flutter.dart';

class FeedDatasource {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchFeedItems(
      int offset, int limit) async {
    final response = await _supabaseClient
        .from('feed_items')
        .select()
        .order('priority', ascending: true)
        .order('feed_timestamp', ascending: false)
        .range(offset, offset + limit - 1);

    final results = response as List<dynamic>;
    return results.cast<Map<String, dynamic>>();
  }
}
