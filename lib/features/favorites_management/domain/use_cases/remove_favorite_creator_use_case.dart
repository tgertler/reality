import '../repositories/favorites_repository.dart';

class RemoveFavoriteCreator {
  final FavoritesRepository repository;

  RemoveFavoriteCreator(this.repository);

  Future<void> call(String userId, String creatorId) async {
    return await repository.removeFavoriteCreator(userId, creatorId);
  }
}
