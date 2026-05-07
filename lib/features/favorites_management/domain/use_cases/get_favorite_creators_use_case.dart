import 'package:frontend/features/favorites_management/domain/entities/creator.dart';
import '../repositories/favorites_repository.dart';

class GetFavoriteCreators {
  final FavoritesRepository repository;

  GetFavoriteCreators(this.repository);

  Future<List<Creator>> call(String userId) async {
    return await repository.getFavoriteCreators(userId);
  }
}
