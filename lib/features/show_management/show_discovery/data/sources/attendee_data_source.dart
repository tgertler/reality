import 'package:supabase_flutter/supabase_flutter.dart';

class AttendeeDataSource {
  final SupabaseClient supabaseClient;

  AttendeeDataSource(this.supabaseClient);

  Future<List<Map<String, dynamic>>> search(String query) async {
    final response = await supabaseClient
        .schema('show_management')
        .from('attendees')
        .select()
        .ilike('name', '%$query%');

    final results = response as List<dynamic>;

    return results
        .map((attendee) => {
              'id': attendee['id'],
              'name': attendee['name'],
              'bio': attendee['bio'],
              'type': 'attendee',
            })
        .toList();
  }
}
