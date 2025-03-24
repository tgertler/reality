import '../repositories/favorites_repository.dart';

class RemoveFavoriteAttendee {
  final FavoritesRepository repository;

  RemoveFavoriteAttendee(this.repository);

  Future<void> call(String userId, String attendeeId) async {
    await repository.removeFavoriteAttendee(userId, attendeeId);
  }
}