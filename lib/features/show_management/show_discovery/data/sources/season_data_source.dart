import 'package:supabase_flutter/supabase_flutter.dart';

class SeasonDataSource {
  final supabaseClient = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getSeasonsByShow(String showId) async {
<<<<<<< HEAD
    final response =
        await supabaseClient.from('seasons').select('*').eq('show_id', showId);
=======
    final response = await supabaseClient
        .schema('show_management')
        .from('seasons')
        .select('*')
        .eq('show_id', showId);
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801

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
<<<<<<< HEAD
    final response =
        await supabaseClient.from('seasons').select().eq('id', id).single();
=======
    final response = await supabaseClient
        .schema('show_management')
        .from('seasons')
        .select()
        .eq('id', id)
        .single();
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801

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
