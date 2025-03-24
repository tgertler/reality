import '../repositories/content_repository.dart';
import '../entities/season.dart';

class GenerateCalendarEvents {
  final ContentRepository repository;

  GenerateCalendarEvents(this.repository);

  Future<void> call(Season season) async {
    return await repository.generateCalendarEvents(season);
  }
}