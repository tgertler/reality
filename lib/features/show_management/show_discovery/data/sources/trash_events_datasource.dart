import 'package:supabase_flutter/supabase_flutter.dart';

class TrashEventsDataSource {
  final SupabaseClient supabaseClient;

  TrashEventsDataSource(this.supabaseClient);

  Future<List<Map<String, dynamic>>> getTrashEventsForShow(
      String showId) async {
    final response = await supabaseClient
        .from('trash_events')
        .select()
        .eq('related_show_id', showId)
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }
}
