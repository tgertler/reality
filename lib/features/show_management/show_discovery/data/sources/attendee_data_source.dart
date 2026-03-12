import 'package:supabase_flutter/supabase_flutter.dart';

class AttendeeDataSource {
  final SupabaseClient supabaseClient;

  AttendeeDataSource(this.supabaseClient);

  Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final response = await supabaseClient
<<<<<<< HEAD
          .from('attendees')
          .select()
          .ilike('name', '%$query%');

      final results = response as List<dynamic>;

      print(response);

      return results
          .map((attendee) => {
                'id': attendee['id'],
                'name': attendee['name'],
                'bio': attendee['bio'],
                'type': 'attendee',
              })
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getShowById(String id) async {
    final response =
        await supabaseClient.from('attendees').select().eq('id', id).single();

    final attendee = response;

=======
          .schema('show_management')
          .from('attendees')
          .select()
          .ilike('name', '%$query%');

      final results = response as List<dynamic>;

      print(response);

      return results
          .map((attendee) => {
                'id': attendee['id'],
                'name': attendee['name'],
                'bio': attendee['bio'],
                'type': 'attendee',
              })
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getShowById(String id) async {
    final response = await supabaseClient
        .schema('show_management')
        .from('attendees')
        .select()
        .eq('id', id)
        .single();

    final attendee = response;

>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
    return {
      'id': attendee['id'],
      'name': attendee['name'],
      'bio': attendee['bio'],
    };
  }
}
