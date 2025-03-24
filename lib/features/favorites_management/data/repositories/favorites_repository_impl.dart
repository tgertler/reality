import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/show.dart';
import '../../domain/entities/attendee.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../sources/favorites_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesDataSource dataSource;
  final Logger _logger = getLogger('FavoritesRepositoryImpl');

  FavoritesRepositoryImpl(this.dataSource);

  @override
  Future<List<Show>> getFavoriteShows(String userId) async {
    _logger.i('Fetching favorite shows for user: $userId');
    try {
      final shows = await dataSource.getFavoriteShows(userId);
      _logger.i('Favorite shows received: $shows');
      return shows.map((show) => Show(showId: show['show_id'], title: show['title'])).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching favorite shows', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Attendee>> getFavoriteAttendees(String userId) async {
    _logger.i('Fetching favorite attendees for user: $userId');
    try {
      final attendees = await dataSource.getFavoriteAttendees(userId);
      _logger.i('Favorite attendees received: $attendees');
      return attendees.map((attendee) => Attendee(attendeeId: attendee['attendee_id'], name: attendee['name'])).toList();
    } catch (e, stackTrace) {
      _logger.e('Error fetching favorite attendees', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addFavoriteShow(String userId, String showId, String title) async {
    _logger.i('Adding favorite show for user: $userId');
    try {
      await dataSource.addFavoriteShow(userId, showId, title);
      _logger.i('Favorite show added successfully');
    } catch (e, stackTrace) {
      _logger.e('Error adding favorite show', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeFavoriteShow(String userId, String showId) async {
    _logger.i('Removing favorite show for user: $userId');
    try {
      await dataSource.removeFavoriteShow(userId, showId);
      _logger.i('Favorite show removed successfully');
    } catch (e, stackTrace) {
      _logger.e('Error removing favorite show', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addFavoriteAttendee(String userId, String attendeeId) async {
    _logger.i('Adding favorite attendee for user: $userId');
    try {
      await dataSource.addFavoriteAttendee(userId, attendeeId);
      _logger.i('Favorite attendee added successfully');
    } catch (e, stackTrace) {
      _logger.e('Error adding favorite attendee', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeFavoriteAttendee(String userId, String attendeeId) async {
    _logger.i('Removing favorite attendee for user: $userId');
    try {
      await dataSource.removeFavoriteAttendee(userId, attendeeId);
      _logger.i('Favorite attendee removed successfully');
    } catch (e, stackTrace) {
      _logger.e('Error removing favorite attendee', e, stackTrace);
      rethrow;
    }
  }

    @override
  Future<bool> isFavoriteShow(String userId, String showId) async {
    _logger.i('Checking if show is favorite for user: $userId');
    try {
      return await dataSource.isFavoriteShow(userId, showId);
    } catch (e, stackTrace) {
      _logger.e('Error checking if show is favorite', e, stackTrace);
      rethrow;
    }
  }

    @override
  Future<bool> isFavoriteAttendee(String userId, String attendeeId) async {
    _logger.i('Checking if show is favorite for user: $userId');
    try {
      return await dataSource.isFavoriteAttendee(userId, attendeeId);
    } catch (e, stackTrace) {
      _logger.e('Error checking if show is favorite', e, stackTrace);
      rethrow;
    }
  }
}