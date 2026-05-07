import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';

import '../repositories/calendar_event_repository.dart';

class GetResolvedCalendarEventsForDate {
  final CalendarEventRepository calendarEventRepository;

  GetResolvedCalendarEventsForDate(this.calendarEventRepository);

  Future<List<ResolvedCalendarEvent>> execute(DateTime date) {
    return calendarEventRepository.getResolvedCalendarEventsByDate(date);
  }
}
