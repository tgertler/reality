import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import '../repositories/calendar_event_repository.dart';

class GetUpcomingEventsForShow {
  final CalendarEventRepository repository;

  GetUpcomingEventsForShow(this.repository);

  Future<List<CalendarEventWithShow>> execute(String showId, {int limit = 3}) {
    return repository.getUpcomingCalendarEventsForShow(showId);
  }
}
