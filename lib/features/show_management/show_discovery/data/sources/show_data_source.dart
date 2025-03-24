import 'package:supabase_flutter/supabase_flutter.dart';

class ShowDataSource {
  final supabaseClient = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> search(String query) async {
    final response =
        await supabaseClient.from('shows').select().ilike('title', '%$query%');

    final results = response as List<dynamic>;

    return results
        .map((show) => {
              'id': show['id'],
              'title': show['title'],
              'description': show['description'],
              'type': 'show',
            })
        .toList();
  }

  Future<Map<String, dynamic>?> getShowById(String id) async {
    final response =
        await supabaseClient.from('shows').select().eq('id', id).single();

    final show = response;

    return {
      'id': show['id'],
      'title': show['title'],
      'description': show['description'],
    };
  }
}
