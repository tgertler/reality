import '../entities/calendar_event_with_show.dart';
import '../repositories/calendar_event_repository.dart';

class GetLastThreePremieres {
  final CalendarEventRepository repository;

  GetLastThreePremieres(this.repository);

  Future<List<CalendarEventWithShow>> execute() async {
    return await repository.getLastThreePremieres();
  }
}
