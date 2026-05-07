import 'package:supabase_flutter/supabase_flutter.dart';

class CreatorEventsDataSource {
  final SupabaseClient supabaseClient;

  CreatorEventsDataSource(this.supabaseClient);

  Future<List<Map<String, dynamic>>> getCreatorEventsForShow(
      String showId) async {
    final response = await supabaseClient
        .from('creator_events')
        .select('*, creators(id, name, avatar_url, youtube_channel_url, tiktok_url)')
        .eq('related_show_id', showId)
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }
}
