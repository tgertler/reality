import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';

const _kFavorite = 'favorite';

class FavoritesDataSource {
  final SupabaseClient supabaseClient;
  final Logger _logger = getLogger('FavoritesDataSource');

  FavoritesDataSource(this.supabaseClient);

  // -- Shows via user_show_relations JOIN shows -------------------------------

  Future<List<Map<String, dynamic>>> getFavoriteShows(String userId) async {
    _logger.i('Fetching favorite shows for user: $userId');
    final response = await supabaseClient
        .from('user_show_relations')
      .select('show_id, shows(id, title, short_title)')
        .eq('user_id', userId)
        .eq('interaction_type', _kFavorite);

    final results = response as List<dynamic>;
    _logger.i('Favorite shows received: ${results.length}');

    return results.map((row) {
      final show = row['shows'] as Map<String, dynamic>?;
      return {
        'show_id': row['show_id'] as String,
        'title': (show?['title'] as String?) ?? '',
        'short_title': show?['short_title'] as String?,
      };
    }).toList();
  }

  Future<void> addFavoriteShow(
      String userId, String showId, String title) async {
    _logger.i('Adding favorite show $showId for user $userId');
    await supabaseClient.from('user_show_relations').upsert(
      {
        'id': const Uuid().v4(),
        'user_id': userId,
        'show_id': showId,
        'interaction_type': _kFavorite,
      },
      onConflict: 'user_id,show_id,interaction_type',
    );
  }

  Future<void> removeFavoriteShow(String userId, String showId) async {
    _logger.i('Removing favorite show $showId for user $userId');
    await supabaseClient
        .from('user_show_relations')
        .delete()
        .eq('user_id', userId)
        .eq('show_id', showId)
        .eq('interaction_type', _kFavorite);
  }

  Future<bool> isFavoriteShow(String userId, String showId) async {
    _logger.i('Checking favorite: user=$userId show=$showId');
    final response = await supabaseClient
        .from('user_show_relations')
        .select('id')
        .eq('user_id', userId)
        .eq('show_id', showId)
        .eq('interaction_type', _kFavorite);

    final results = response as List<dynamic>;
    return results.isNotEmpty;
  }

  Future<int> getFavoriteShowCount(String showId) async {
    _logger.i('Counting favorites for show: $showId');
    final response = await supabaseClient
        .from('user_show_relations')
        .select()
        .eq('show_id', showId)
        .eq('interaction_type', _kFavorite);
    return (response as List).length;
  }

  // -- Attendees (legacy table) ----------------------------------------------

  Future<List<Map<String, dynamic>>> getFavoriteAttendees(
      String userId) async {
    _logger.i('Fetching favorite attendees for user: $userId');
    final response = await supabaseClient
        .from('favorite_attendees')
        .select()
        .eq('user_id', userId);

    final results = response as List<dynamic>;
    return results
        .map((a) => {
              'attendee_id': a['attendee_id'] as String,
              'name': (a['name'] as String?) ?? '',
            })
        .toList();
  }

  Future<void> addFavoriteAttendee(
      String userId, String attendeeId) async {
    await supabaseClient
        .from('favorite_attendees')
        .insert({'user_id': userId, 'attendee_id': attendeeId});
  }

  Future<void> removeFavoriteAttendee(
      String userId, String attendeeId) async {
    await supabaseClient
        .from('favorite_attendees')
        .delete()
        .eq('user_id', userId)
        .eq('attendee_id', attendeeId);
  }

  Future<bool> isFavoriteAttendee(String userId, String attendeeId) async {
    final response = await supabaseClient
        .from('favorite_attendees')
        .select()
        .eq('user_id', userId)
        .eq('attendee_id', attendeeId);

    final results = response as List<dynamic>;
    return results.isNotEmpty;
  }

  // -- Creators via user_creator_relations -----------------------------------

  Future<List<Map<String, dynamic>>> getFavoriteCreators(String userId) async {
    _logger.i('Fetching favorite creators for user: $userId');
    final response = await supabaseClient
        .from('user_creator_relations')
        .select('creator_id, creators(id, name)')
        .eq('user_id', userId)
        .eq('interaction_type', _kFavorite);

    final results = response as List<dynamic>;
    _logger.i('Favorite creators received: ${results.length}');

    return results.map((row) {
      final creator = row['creators'] as Map<String, dynamic>?;
      return {
        'creator_id': row['creator_id'] as String,
        'name': (creator?['name'] as String?) ?? '',
      };
    }).toList();
  }

  Future<void> addFavoriteCreator(
      String userId, String creatorId, String name) async {
    _logger.i('Adding favorite creator $creatorId for user $userId');
    await supabaseClient.from('user_creator_relations').upsert({
      'id': const Uuid().v4(),
      'user_id': userId,
      'creator_id': creatorId,
      'interaction_type': _kFavorite,
    });
  }

  Future<void> removeFavoriteCreator(
      String userId, String creatorId) async {
    _logger.i('Removing favorite creator $creatorId for user $userId');
    await supabaseClient
        .from('user_creator_relations')
        .delete()
        .eq('user_id', userId)
        .eq('creator_id', creatorId)
        .eq('interaction_type', _kFavorite);
  }

  Future<bool> isFavoriteCreator(String userId, String creatorId) async {
    _logger.i('Checking favorite: user=$userId creator=$creatorId');
    final response = await supabaseClient
        .from('user_creator_relations')
        .select('id')
        .eq('user_id', userId)
        .eq('creator_id', creatorId)
        .eq('interaction_type', _kFavorite);

    final results = response as List<dynamic>;
    return results.isNotEmpty;
  }
}
