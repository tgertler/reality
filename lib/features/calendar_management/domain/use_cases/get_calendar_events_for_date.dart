import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../entities/calendar_event.dart';
import '../repositories/calendar_event_repository.dart';

class GetCalendarEventsForDate {
  final CalendarEventRepository calendarEventRepository;
  final Logger _logger = getLogger('GetCalendarEventsForDate');

  GetCalendarEventsForDate(this.calendarEventRepository);

  Future<List<CalendarEvent>> execute(DateTime date) async {
    _logger.i('Starting search for events on date: $date');
    try {
      final events = await calendarEventRepository.getEventsByDate(date);
      _logger.i('Events received: $events');
      return events;
    } catch (e, stackTrace) {
      _logger.e('Error during search for events', e, stackTrace);
      rethrow;
    }
  }
}