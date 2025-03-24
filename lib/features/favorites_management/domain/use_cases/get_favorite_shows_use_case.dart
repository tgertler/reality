import 'package:frontend/features/favorites_management/domain/entities/show.dart';

import '../repositories/favorites_repository.dart';

class GetFavoriteShows {
  final FavoritesRepository repository;

  GetFavoriteShows(this.repository);

  Future<List<Show>> call(String userId) async {
    return await repository.getFavoriteShows(userId);
  }
}