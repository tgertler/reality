import '../repositories/favorites_repository.dart';

class AddFavoriteShow {
  final FavoritesRepository repository;

  AddFavoriteShow(this.repository);

  Future<void> call(String userId, String showId, String title) async {
    await repository.addFavoriteShow(userId, showId, title);
  }
}