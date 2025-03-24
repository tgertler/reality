import '../repositories/favorites_repository.dart';

class IsFavoriteShow {
  final FavoritesRepository repository;

  IsFavoriteShow(this.repository);

  Future<bool> call(String userId, String showId) async {
    return await repository.isFavoriteShow(userId, showId);
  }
}