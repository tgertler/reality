import '../repositories/favorites_repository.dart';

class GetFavoriteShowCount {
  final FavoritesRepository repository;

  GetFavoriteShowCount(this.repository);

  Future<int> call(String showId) async {
    return await repository.getFavoriteShowCount(showId);
  }
}
