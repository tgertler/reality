import 'package:supabase_flutter/supabase_flutter.dart';

class CreatorDataSource {
  final SupabaseClient supabaseClient;

  CreatorDataSource(this.supabaseClient);

  Future<List<Map<String, dynamic>>> search(String query) async {
    final escaped = query.replaceAll(',', r'\\,');
    final response = await supabaseClient
        .from('creators')
        .select('id, name, description, avatar_url, youtube_channel_url, instagram_url, tiktok_url')
        .or('name.ilike.%$escaped%,description.ilike.%$escaped%')
        .limit(20);

    final results = response as List<dynamic>;
    return results
        .map((row) => {
              'id': row['id'],
              'name': row['name'],
              'description': row['description'],
              'avatar_url': row['avatar_url'],
              'youtube_channel_url': row['youtube_channel_url'],
              'instagram_url': row['instagram_url'],
              'tiktok_url': row['tiktok_url'],
              'type': 'creator',
            })
        .toList();
  }
}