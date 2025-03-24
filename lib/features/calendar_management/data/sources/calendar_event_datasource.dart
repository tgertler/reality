import 'package:frontend/features/calendar_management/domain/entities/season.dart';
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
    _logger.i(
        'Fetching calendar events with shows for date: $date, showIds: $showIds, attendeeIds: $attendeeIds');
    final response = await supabaseClient
        .rpc('get_calendar_events_with_shows_by_date', params: {
      'event_date': date.toIso8601String(),
      'attendee_ids': attendeeIds,
      'show_ids': showIds,
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
              season: Season(
                seasonId: event['season_id'].toString(),
                showId: event['show_id'].toString(),
                seasonNumber: event['season_number'],
                totalEpisodes: event['total_episodes'],
                streamingOption: event['streaming_option'],
              ),
            ))
        .toList();
  }

  Future<List<CalendarEventWithShow>> getNextThreePremieres() async {
    final response = await supabaseClient
        .from('calendar_events')
        .select('*, shows(title), seasons(*)')
        .eq('event_type', 'premiere')
        .gte('start_datetime', DateTime.now().toIso8601String())
        .range(0, 2)
        .order('start_datetime', ascending: false);

    final results = response as List<dynamic>;

    return results
        .map((event) => CalendarEventWithShow(
              calendarEvent: CalendarEvent(
                calendarEventId: event['id'],
                showId: event['show_id'],
                seasonId: event['season_id'],
                startDatetime: DateTime.parse(event['start_datetime']),
                endDatetime: DateTime.parse(event['end_datetime']),
              ),
              show: Show(
                showId: event['show_id'],
                title: event['shows']['title'],
              ),
              season: Season(
                seasonId: event['season_id'].toString(),
                showId: event['show_id'].toString(),
                seasonNumber: event['season_number'] ?? 0,
                totalEpisodes: event['total_episodes'] ?? 0,
                streamingOption: event['streaming_option'] ?? '',
              ),
            ))
        .toList();
  }

  Future<List<CalendarEventWithShow>> getLastThreePremieres() async {
    final response = await supabaseClient
        .from('calendar_events')
        .select('*, shows(title), seasons(streaming_option)')
        .eq('event_type', 'premiere')
        .lte('start_datetime', DateTime.now().toIso8601String())

/*         .gte('start_datetime',
            DateTime.now().subtract(Duration(days: 7)).toIso8601String())
        .lte('start_datetime', DateTime.now().toIso8601String()) */
        .range(0, 2)
        .order('start_datetime', ascending: false);

    final results = response as List<dynamic>;

    return results
        .map((event) => CalendarEventWithShow(
              calendarEvent: CalendarEvent(
                calendarEventId: event['id'],
                showId: event['show_id'],
                seasonId: event['season_id'],
                startDatetime: DateTime.parse(event['start_datetime']),
                endDatetime: DateTime.parse(event['end_datetime']),
              ),
              show: Show(
                showId: event['show_id'],
                title: event['shows']['title'],
              ),
              season: Season(
                seasonId: event['season_id'].toString(),
                showId: event['show_id'].toString(),
                seasonNumber: event['season_number'] ?? 0,
                totalEpisodes: event['total_episodes'] ?? 0,
                streamingOption: event['seasons']['streaming_option'] ?? '',
              ),
            ))
        .toList();
  }

  Future<List<CalendarEventWithShow>> getUpcomingCalendarEventsForShow(
      String showId) async {
    final now = DateTime.now();
    _logger.i('Fetching all upcoming events from $now');

    final response = await supabaseClient
        .from('calendar_events')
        .select(
            '*, shows(title), seasons(season_number,total_episodes,streaming_option)')
        .eq('show_id', showId)
        .gte(
            'start_datetime', now.subtract(Duration(days: 1)).toIso8601String())
        .order('start_datetime', ascending: true);

    final results = response as List<dynamic>;
    _logger.i('Fetched ${results.length} upcoming events');

    return results
        .map((event) => CalendarEventWithShow(
              calendarEvent: CalendarEvent(
                calendarEventId: event['id'].toString(),
                showId: event['show_id'].toString(),
                seasonId: event['season_id'].toString(),
                startDatetime: DateTime.parse(event['start_datetime']),
                endDatetime: DateTime.parse(event['end_datetime']),
              ),
              show: Show(
                showId: event['show_id'].toString(),
                title: event['shows']?['title'] ?? '',
              ),
              season: Season(
                seasonId: event['season_id']?.toString() ?? '',
                showId: event['show_id']?.toString() ?? '',
                seasonNumber: event['seasons']?['season_number'] ??
                    (event['season_number'] ?? 0),
                totalEpisodes: event['seasons']?['total_episodes'] ??
                    (event['total_episodes'] ?? 0),
                streamingOption: event['seasons']?['streaming_option'] ??
                    (event['streaming_option'] ?? ''),
              ),
            ))
        .toList();
  }

  /// Holt das nächste einzelne Calendar Event für eine Show (nächstes start_datetime >= jetzt)
  Future<CalendarEventWithShow?> getNextCalendarEventForShow(
      String showId) async {
    final now = DateTime.now();
    _logger.i('Fetching next calendar event for show $showId from $now');

    final response = await supabaseClient
        .from('calendar_events')
        .select(
            '*, shows(title), seasons(season_number,total_episodes,streaming_option)')
        .eq('show_id', showId)
        .gte(
            'start_datetime', now.subtract(Duration(days: 1)).toIso8601String())
        .order('start_datetime', ascending: true)
        .limit(1)
        .maybeSingle(); // gibt null zurück, falls kein Event gefunden

    if (response == null) {
      _logger.i('No upcoming event found for show $showId');
      return null;
    }

    _logger.i('Fetched next event: ${response['id']}');

    return CalendarEventWithShow(
      calendarEvent: CalendarEvent(
        calendarEventId: response['id'].toString(),
        showId: response['show_id'].toString(),
        seasonId: response['season_id'].toString(),
        startDatetime: DateTime.parse(response['start_datetime']),
        endDatetime: DateTime.parse(response['end_datetime']),
      ),
      show: Show(
        showId: response['show_id'].toString(),
        title: response['shows']?['title'] ?? '',
      ),
      season: Season(
        seasonId: response['season_id']?.toString() ?? '',
        showId: response['show_id']?.toString() ?? '',
        seasonNumber: response['seasons']?['season_number'] ??
            (response['season_number'] ?? 0),
        totalEpisodes: response['seasons']?['total_episodes'] ??
            (response['total_episodes'] ?? 0),
        streamingOption: response['seasons']?['streaming_option'] ??
            (response['streaming_option'] ?? ''),
      ),
    );
  }
}
