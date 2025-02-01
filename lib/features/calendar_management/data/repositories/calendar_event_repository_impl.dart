import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/calendar_event_with_show.dart';
import '../../domain/repositories/calendar_event_repository.dart';
import '../sources/calendar_event_datasource.dart';

class CalendarEventRepositoryImpl implements CalendarEventRepository {
  final CalendarEventDataSource dataSource;
  final Logger _logger = getLogger('CalendarEventRepositoryImpl');

  CalendarEventRepositoryImpl(this.dataSource);

  @override
  Future<List<CalendarEvent>> getEventsByDate(DateTime date) async {
    _logger.i('Fetching calendar events for date: $date');
    try {
      final events = dataSource.getCalendarEventsByDate(date);
      _logger.i('Calendar events for date $date received: $events');
      return events;
    } catch (e, stackTrace) {
      _logger.e('Error fetching calendar events for date $date', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<CalendarEvent> getEventById(String id) async {
    _logger.i('Fetching calendar event for id: $id');
    try {
      final event = dataSource.getCalendarEventById(id);
      _logger.i('Calendar events for ID $id received: $event');
      return event;
    } catch (e, stackTrace) {
      _logger.e('Error fetching calendar event for ID $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<CalendarEventWithShow>> getCalendarEventsWithShowsByDate(DateTime date, List<String> showIds, List<String> attendeeIds) async {
    _logger.i('Fetching calendar events with shows for date: $date');
    try {
      final eventsWithShows = dataSource.getCalendarEventsWithShowsByDate(date, showIds, attendeeIds);
      _logger.i('Calendar events with shows for date $date received: $eventsWithShows');
      return eventsWithShows;
    } catch (e, stackTrace) {
      _logger.e('Error fetching calendar events with shows for date $date', e, stackTrace);
      rethrow;
    }
  }

}