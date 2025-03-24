import '../repositories/favorites_repository.dart';

class RemoveFavoriteShow {
  final FavoritesRepository repository;

  RemoveFavoriteShow(this.repository);

  Future<void> call(String userId, String showId) async {
    await repository.removeFavoriteShow(userId, showId);
  }
}