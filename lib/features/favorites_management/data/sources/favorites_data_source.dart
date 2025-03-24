import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';

class FavoritesDataSource {
  final SupabaseClient supabaseClient;
  final Logger _logger = getLogger('FavoritesDataSource');

  FavoritesDataSource(this.supabaseClient);

  Future<List<Map<String, dynamic>>> getFavoriteShows(String userId) async {
    _logger.i('Fetching favorite shows for user: $userId');
    final response = await supabaseClient
        .schema('show_management')
        .from('favorite_shows')
        .select()
        .eq('user_id', userId);

    final results = response as List<dynamic>;
    _logger.i('Favorite shows received: $results');

    return results.map((show) => {
      'show_id': show['show_id'],
      'title': show['title'],
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFavoriteAttendees(String userId) async {
    _logger.i('Fetching favorite attendees for user: $userId');
    final response = await supabaseClient
        .schema('show_management')
        .from('favorite_attendees')
        .select()
        .eq('user_id', userId);

    final results = response as List<dynamic>;
    _logger.i('Favorite attendees received: $results');

    return results.map((attendee) => {
      'attendee_id': attendee['attendee_id'],
      'name': attendee['name'],
    }).toList();
  }

    Future<void> addFavoriteShow(String userId, String showId, String title) async {
    _logger.i('Adding favorite show for user: $userId');
    await supabaseClient
        .schema('show_management')
        .from('favorite_shows')
        .insert({'user_id': userId, 'show_id': showId, 'title': title});
  }

  Future<void> removeFavoriteShow(String userId, String showId) async {
    _logger.i('Removing favorite show for user: $userId');
    await supabaseClient
        .schema('show_management')
        .from('favorite_shows')
        .delete()
        .eq('user_id', userId)
        .eq('show_id', showId);
  }

  Future<void> addFavoriteAttendee(String userId, String attendeeId) async {
    _logger.i('Adding favorite attendee for user: $userId');
    await supabaseClient
        .schema('show_management')
        .from('favorite_attendees')
        .insert({'user_id': userId, 'attendee_id': attendeeId});
  }

  Future<void> removeFavoriteAttendee(String userId, String attendeeId) async {
    _logger.i('Removing favorite attendee for user: $userId');
    await supabaseClient
        .schema('show_management')
        .from('favorite_attendees')
        .delete()
        .eq('user_id', userId)
        .eq('attendee_id', attendeeId);
  }

    Future<bool> isFavoriteShow(String userId, String showId) async {
    _logger.i('Checking if show is favorite for user: $userId');
    final response = await supabaseClient
        .schema('show_management')
        .from('favorite_shows')
        .select()
        .eq('user_id', userId)
        .eq('show_id', showId);

    final results = response as List<dynamic>;
    _logger.i('Favorite show check result: $results');

    return results.isNotEmpty;
  }

      Future<bool> isFavoriteAttendee(String userId, String attendeeIds) async {
    _logger.i('Checking if show is favorite for user: $userId');
    final response = await supabaseClient
        .schema('show_management')
        .from('favorite_attendees')
        .select()
        .eq('user_id', userId)
        .eq('attendee_id', attendeeIds);

    final results = response as List<dynamic>;
    _logger.i('Favorite show check result: $results');

    return results.isNotEmpty;
  }
}