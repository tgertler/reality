import '../repositories/favorites_repository.dart';

class AddFavoriteCreator {
  final FavoritesRepository repository;

  AddFavoriteCreator(this.repository);

  Future<void> call(String userId, String creatorId, String name) async {
    return await repository.addFavoriteCreator(userId, creatorId, name);
  }
}
