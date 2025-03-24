import '../repositories/favorites_repository.dart';

class IsFavoriteAttendee {
  final FavoritesRepository repository;

  IsFavoriteAttendee(this.repository);

  Future<bool> call(String userId, String attendeeId) async {
    return await repository.isFavoriteAttendee(userId, attendeeId);
  }
}