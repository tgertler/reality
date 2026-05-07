import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/calendar_event_with_show.dart';
import '../../domain/entities/resolved_calendar_event.dart';
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
  Future<List<CalendarEventWithShow>> getCalendarEventsWithShowsByDate(
      DateTime date, List<String> showIds, List<String> attendeeIds) async {
    _logger.i('Fetching calendar events with shows for date: $date');
    try {
      // Uses the direct-query replacement (RPC was commented out in datasource)
      final eventsWithShows =
          await dataSource.getCalendarEventsWithShowsByDateDirect(
              date, showIds, attendeeIds);
      _logger.i(
          'Calendar events with shows for date $date received: ${eventsWithShows.length}');
      return eventsWithShows;
    } catch (e, stackTrace) {
      _logger.e('Error fetching calendar events with shows for date $date', e,
          stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ResolvedCalendarEvent>> getResolvedCalendarEventsByDate(
      DateTime date) async {
    _logger.i('Fetching resolved calendar events for date: $date');
    try {
      final events =
          await dataSource.getResolvedCalendarEventsByDate(date);
      _logger.i('Resolved calendar events for $date: ${events.length}');
      return events;
    } catch (e, stackTrace) {
      _logger.e(
          'Error fetching resolved calendar events for date $date', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<CalendarEventWithShow>> getNextThreePremieres() async {
    _logger.i('Fetching next three premieres');
    try {
      final response = await dataSource.getNextThreePremieres();
      _logger.i('Received response: $response');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Error fetching next three premieres', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<CalendarEventWithShow>> getLastThreePremieres() async {
    _logger.i('Fetching last three premieres');
    try {
      final response = await dataSource.getLastThreePremieres();
      _logger.i('Received response: $response');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Error fetching last three premieres', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<CalendarEventWithShow>> getUpcomingCalendarEventsForShow(
      String showId) async {
    _logger.i('Fetching upcoming calendar events for show: $showId');
    try {
      final response =
          await dataSource.getUpcomingCalendarEventsForShow(showId);
      _logger.i('Received response: $response');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming calendar events for show: $showId', e,
          stackTrace);
      rethrow;
    }
  }

  @override
  Future<CalendarEventWithShow?> getNextCalendarEventForShow(
      String showId) async {
    _logger.i('Fetching next calendar event for show: $showId');
    try {
      final response = await dataSource.getNextCalendarEventForShow(showId);
      _logger.i('Received response: $response');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Error next calendar event for show: $showId', e, stackTrace);
      rethrow;
    }
  }
}
