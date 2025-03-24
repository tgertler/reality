import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/season.dart';

class SeasonDataSource {
  final SupabaseClient supabaseClient;

  SeasonDataSource(this.supabaseClient);

  Future<List<Season>> getSeasons() async {
    final response =
        await supabaseClient.schema('show_management').from('seasons').select();

    final results = response as List<dynamic>;

    return results
        .map((season) => Season(
              seasonId: season['id'],
              showId: season['show_id'],
              seasonNumber: season['season_number'],
              totalEpisodes: season['total_episodes'],
              streamingOption: season['streaming_option'],
            ))
        .toList();
  }

  Future<List<Season>> getSeasonsForShow(String showId) async {
    final response = await supabaseClient
        .schema('show_management')
        .from('seasons')
        .select()
        .eq('show_id', showId);

    final results = response as List<dynamic>;

    return results
        .map((season) => Season(
              seasonId: season['id'],
              showId: season['show_id'],
              seasonNumber: season['season_number'],
              totalEpisodes: season['total_episodes'],
              streamingOption: season['streaming_option'],
            ))
        .toList();
  }
}
