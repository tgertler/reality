import 'package:frontend/features/favorites_management/domain/entities/attendee.dart';

import '../repositories/favorites_repository.dart';

class GetFavoriteAttendees {
  final FavoritesRepository repository;

  GetFavoriteAttendees(this.repository);

  Future<List<Attendee>> call(String userId) async {
    return await repository.getFavoriteAttendees(userId);
  }
}