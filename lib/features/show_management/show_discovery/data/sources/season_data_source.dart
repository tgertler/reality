import 'package:supabase_flutter/supabase_flutter.dart';

class SeasonDataSource {
  final supabaseClient = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getSeasonsByShow(String showId) async {
    final response =
        await supabaseClient.from('seasons').select('*').eq('show_id', showId);

    final results = response as List<dynamic>;

    return results.map((season) {
      return {
        'id': season['id'],
        'show_id': season['show_id'],
        'season_number': season['season_number'],
        'release_frequency': season['release_frequency'],
        'total_episodes': season['total_episodes'],
        'episode_length': season['episode_length'],
        'streaming_release_date': season['streaming_release_date'],
        'streaming_release_time': season['streaming_release_time'],
        'streaming_option': season['streaming_option'],
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getSeasonById(String id) async {
    final response =
        await supabaseClient.from('seasons').select().eq('id', id).single();

    final season = response;

    return {
      'id': season['id'],
      'show_id': season['show_id'],
      'season_number': season['season_number'],
      'release_frequency': season['release_frequency'],
      'total_episodes': season['total_episodes'],
      'episode_length': season['episode_length'],
      'streaming_release_date': season['streaming_release_date'],
      'streaming_release_time': season['streaming_release_time'],
      'streaming_option': season['streaming_option'],
    };
  }
}
