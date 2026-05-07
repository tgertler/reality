import 'package:supabase_flutter/supabase_flutter.dart';

class ShowSocialDataSource {
  final SupabaseClient supabaseClient;

  ShowSocialDataSource(this.supabaseClient);

  Future<List<Map<String, dynamic>>> getTagsForShow(String showId) async {
    final response = await supabaseClient
        .from('show_social_tags')
        .select()
        .eq('show_id', showId)
        .order('is_primary', ascending: false)
        .order('priority', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getVideosForShow(String showId) async {
    final response = await supabaseClient
        .from('show_social_videos')
        .select()
        .eq('show_id', showId)
        .order('priority', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }
}
