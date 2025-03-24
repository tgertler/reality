import '../entities/calendar_event_with_show.dart';
import '../repositories/calendar_event_repository.dart';

class GetNextThreePremieres {
  final CalendarEventRepository repository;

  GetNextThreePremieres(this.repository);

  Future<List<CalendarEventWithShow>> execute() async {
    return await repository.getNextThreePremieres();
  }
}
