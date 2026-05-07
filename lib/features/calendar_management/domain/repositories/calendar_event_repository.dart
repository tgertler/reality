import '../entities/calendar_event.dart';
import '../entities/calendar_event_with_show.dart';
import '../entities/resolved_calendar_event.dart';

abstract class CalendarEventRepository {
  Future<List<CalendarEvent>> getEventsByDate(DateTime date);
  Future<CalendarEvent> getEventById(String id);
  Future<List<CalendarEventWithShow>> getCalendarEventsWithShowsByDate(
      DateTime date, List<String> showIds, List<String> attendeeIds);
  Future<List<CalendarEventWithShow>> getNextThreePremieres();
  Future<List<CalendarEventWithShow>> getLastThreePremieres();
  Future<List<CalendarEventWithShow>> getUpcomingCalendarEventsForShow(
      String showId);
  Future<CalendarEventWithShow?> getNextCalendarEventForShow(String showId);

  /// Queries the `calendar_event_resolved` view — returns all event types
  /// (show_events, creator_events, trash_events) for the given date.
  Future<List<ResolvedCalendarEvent>> getResolvedCalendarEventsByDate(
      DateTime date);
}
