import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import '../repositories/calendar_event_repository.dart';

class GetNextCalendarEventForShow {
  final CalendarEventRepository repository;

  GetNextCalendarEventForShow(this.repository);

  Future<CalendarEventWithShow?> execute(String showId) {
    return repository.getNextCalendarEventForShow(showId);
  }
}
