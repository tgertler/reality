import 'package:frontend/features/favorites_management/domain/entities/attendee.dart';
import 'package:frontend/features/favorites_management/domain/entities/show.dart';

abstract class FavoritesRepository {
  Future<List<Show>> getFavoriteShows(String userId);
  Future<List<Attendee>> getFavoriteAttendees(String userId);
  Future<void> addFavoriteShow(String userId, String showId, String title);
  Future<void> removeFavoriteShow(String userId, String showId);
  Future<void> addFavoriteAttendee(String userId, String attendeeId);
  Future<void> removeFavoriteAttendee(String userId, String attendeeId);
  Future<bool> isFavoriteShow(String userId, String showId);
  Future<bool> isFavoriteAttendee(String userId, String attendeeId);
}
