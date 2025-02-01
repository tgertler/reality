import 'package:frontend/features/calendar_management/domain/entities/show.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/season.dart';

class ShowDataSource {
  final SupabaseClient supabaseClient;

  ShowDataSource(this.supabaseClient);

  Future<List<Show>> getShows() async {
    final response = await supabaseClient
        .schema('show_management')
        .from('shows')
        .select();

    final results = response as List<dynamic>;

    return results
        .map((show) => Show(
              showId: show['id'],
              title: show['title'],
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
              seasonNumber: season['seasonNumber'],
              totalEpisodes: season['totalEpisodes'],
            ))
        .toList();
  }
}
