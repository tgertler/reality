import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/utils/logger.dart';
import '../repositories/calendar_event_repository.dart';

class GetCalendarEventsWithShowsForDate {
  final CalendarEventRepository calendarEventRepository;
  final Logger _logger = getLogger('GetCalendarEventsWithShowsForDate');

  GetCalendarEventsWithShowsForDate(this.calendarEventRepository);

  Future<List<CalendarEventWithShow>> execute(
      DateTime date, List<String> showIds, List<String> attendeeIds) async {
    _logger.i('Starting search for events on date: $date');

    // Ensure UUIDs are valid
    for (final showId in showIds) {
      if (!Uuid.isValidUUID(fromString: showId)) {
        throw FormatException('Invalid UUID: $showId');
      }
    }
    for (final attendeeId in attendeeIds) {
      if (!Uuid.isValidUUID(fromString: attendeeId)) {
        throw FormatException('Invalid UUID: $attendeeId');
      }
    }

    try {
      final events = await calendarEventRepository
          .getCalendarEventsWithShowsByDate(date, showIds, attendeeIds);
      _logger.i('Events received: ${events.length} events');
      return events;
    } catch (e, stackTrace) {
      _logger.e('Error during search for events', e, stackTrace);
      rethrow;
    }
  }
}