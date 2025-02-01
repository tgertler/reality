import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/calendar_event_with_show.dart';
import '../../domain/entities/show.dart';

class CalendarEventDataSource {
  final SupabaseClient supabaseClient;
  final Logger _logger = getLogger('CalendarEventDataSource');

  CalendarEventDataSource(this.supabaseClient);

  Future<List<CalendarEvent>> getCalendarEventsByDate(DateTime date) async {
    final response = await supabaseClient
        .from('calendar_events')
        .select()
        .gte('start_datetime', date.toIso8601String())
        .lt('start_datetime', date.add(Duration(days: 1)).toIso8601String());

    final results = response as List<dynamic>;

    return results
        .map((event) => CalendarEvent(
              calendarEventId: event['id'],
              showId: event['show_id'],
              seasonId: event['season_id'],
              startDatetime: DateTime.parse(event['start_datetime']),
              endDatetime: DateTime.parse(event['end_datetime']),
            ))
        .toList();
  }

  Future<CalendarEvent> getCalendarEventById(String id) async {
    final response = await supabaseClient
        .from('calendar_events')
        .select()
        .eq('id', id)
        .single();

    final event = response;

    return CalendarEvent(
      calendarEventId: event['id'],
      showId: event['show_id'],
      seasonId: event['season_id'],
      startDatetime: DateTime.parse(event['start_datetime']),
      endDatetime: DateTime.parse(event['end_datetime']),
    );
  }

  Future<List<CalendarEventWithShow>> getCalendarEventsWithShowsByDate(
      DateTime date, List<String> showIds, List<String> attendeeIds) async {
    // Convert String lists to int lists
    List<int> showIdsInt = showIds.map(int.parse).toList();
    List<int> attendeeIdsInt = attendeeIds.map(int.parse).toList();
    _logger.i(
        'Fetching calendar events with shows for date: $date, showIds: $showIdsInt, attendeeIds: $attendeeIdsInt');
    final response = await supabaseClient
        .schema("show_management")
        .rpc('get_calendar_events_with_shows_by_date', params: {
      'event_date': date.toIso8601String(),
      'attendee_ids': attendeeIdsInt,
      'show_ids': showIdsInt,
    });

    final results = response as List<dynamic>;
    _logger.i(
        'Fetched ${results.length} calendar events with shows for date: $date');

    return results
        .map((event) => CalendarEventWithShow(
              calendarEvent: CalendarEvent(
                calendarEventId: event['calendar_event_id'].toString(),
                showId: event['show_id'].toString(),
                seasonId: event['season_id'].toString(),
                startDatetime: DateTime.parse(event['start_datetime']),
                endDatetime: DateTime.parse(event['end_datetime']),
              ),
              show: Show(
                showId: event['show_id'].toString(),
                title: event['show_title'],
              ),
            ))
        .toList();
  }
}
