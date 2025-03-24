import '../repositories/content_repository.dart';
import '../entities/season.dart';

class AddSeason {
  final ContentRepository repository;

  AddSeason(this.repository);

  Future<void> call(Season season) async {
    await repository.addSeason(season);
  }
}