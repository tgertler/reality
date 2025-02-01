import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../entities/calendar_event.dart';
import '../repositories/calendar_event_repository.dart';

class GetCalendarEventById {
  final CalendarEventRepository calendarEventRepository;
  final Logger _logger = getLogger('GetCalendarEventById');

  GetCalendarEventById(this.calendarEventRepository);

  Future<CalendarEvent> execute(String id) async {
    _logger.i('Starting search for event by id: $id');
    try {
      final event = await calendarEventRepository.getEventById(id);
      _logger.i('Event received: $event');
      return event;
    } catch (e, stackTrace) {
      _logger.e('Error during search for event', e, stackTrace);
      rethrow;
    }
  }
}