import '../repositories/favorites_repository.dart';

class IsFavoriteCreator {
  final FavoritesRepository repository;

  IsFavoriteCreator(this.repository);

  Future<bool> call(String userId, String creatorId) async {
    return await repository.isFavoriteCreator(userId, creatorId);
  }
}
