import '../repositories/favorites_repository.dart';

class AddFavoriteAttendee {
  final FavoritesRepository repository;

  AddFavoriteAttendee(this.repository);

  Future<void> call(String userId, String attendeeId) async {
    await repository.addFavoriteAttendee(userId, attendeeId);
  }
}