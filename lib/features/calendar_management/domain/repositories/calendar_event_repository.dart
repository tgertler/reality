import '../entities/calendar_event.dart';
import '../entities/calendar_event_with_show.dart';

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
}
